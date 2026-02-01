import Foundation
import OpenAPIRuntime

import VoteHandling

public typealias DefaultRoomHandler = RoomHandler<DefaultRoomManager<DefaultRoomCodeGenerator>>

public struct RoomHandler<RoomManager: RoomManagerProtocol>: APIProtocol {

    let roomManager: RoomManager

    public init(roomManager: RoomManager = DefaultRoomManager()) {
        self.roomManager = roomManager
    }

}

public extension RoomHandler {

    // MARK: - Room Management

    func postRoomCreate(
        _ input: Operations.PostRoomCreate.Input
    ) async throws -> Operations.PostRoomCreate.Output {
        switch input.body {
            case .json(let roomCreationRequest):
                do {
                    let name = roomCreationRequest.name
                    let fields = roomCreationRequest.fields
                    let (code, adminToken) = try await roomManager.createRoom(name: name, fields: fields ?? [])
                    return .ok(.init(body: .json(.init(name: name, fields: fields, code: code, adminToken: adminToken))))
                } catch let error as RoomError where .failedToGenerateCode == error {
                    return .internalServerError(.init(body: .json(.init(reason: error.localizedDescription))))
                }
        }
    }

    // MARK: - Room Info

    func getRoomInfoCode(
        _ input: Operations.GetRoomInfoCode.Input
    ) async throws -> Operations.GetRoomInfoCode.Output {
        let code = input.path.code
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        return .ok(.init(body: .json(.init(name: room.name, code: room.code, fields: room.fields))))
    }

    // MARK: - Join Requests

    func postRoomJoinCode(
        _ input: Operations.PostRoomJoinCode.Input
    ) async throws -> Operations.PostRoomJoinCode.Output {
        let code = input.path.code
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        switch input.body {
            case .json(let joinRequest):
                let name = joinRequest.name
                let fields = joinRequest.fields?.additionalProperties
                // NOTE: This can suspend for a very long time
                let result = try await room.requestJoinRoom(name: name, fields: fields ?? [:])
                switch result {
                    case .success(let participantToken):
                        return .ok(.init(body: .json(.init(participantToken: participantToken))))
                    case .rejected, .timeout:
                        return .forbidden
                    case .roomClosing:
                        return .notFound
                }
        }
    }

    func getRoomJoinRequestsCode(
        _ input: Operations.GetRoomJoinRequestsCode.Input
    ) async throws -> Operations.GetRoomJoinRequestsCode.Output {
        let code = input.path.code
        let adminToken = input.headers.roomAdminToken
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        guard room.verifyAdminToken(adminToken) else {
            return .forbidden
        }
        return .ok(.init(body: .json(.init(
            lastUpdated: Date.now.ISO8601Format(), 
            requests: await room.joinRequests.map { token, request in
                let outFields = request.fields.isEmpty
                    ? nil
                    : Components.Schemas.Fields(additionalProperties: request.fields)
                return .init(
                    name: request.name,
                    participantToken: token,
                    timestamp: request.timestamp.ISO8601Format(),
                    fields: outFields
                )
            }
        ))))
    }

    func postRoomJoinRequestsCode(
        _ input: Operations.PostRoomJoinRequestsCode.Input
    ) async throws -> Operations.PostRoomJoinRequestsCode.Output {
        let code = input.path.code
        let adminToken = input.headers.roomAdminToken
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        guard room.verifyAdminToken(adminToken) else {
            return .forbidden
        }
        var accepted = [String]()
        var rejected = [String]()
        var failed = [String]()
        switch input.body {
            case .json(let payload):
                if let toAccept = payload.accept {
                    for token in toAccept {
                        let result = await room.handleJoinRequest(true, forToken: token)
                        if case .success = result {
                            accepted.append(token)
                        } else {
                            failed.append(token)
                        }
                    }
                }
                if let toReject = payload.reject {
                    for token in toReject {
                        let result = await room.handleJoinRequest(false, forToken: token)
                        if case .success = result {
                            rejected.append(token)
                        } else {
                            failed.append(token)
                        }
                    }
                }
        }
        let result = Components.Schemas.JoinRequestsResult(
            accepted: accepted.isEmpty ? nil : accepted, 
            rejected: rejected.isEmpty ? nil : rejected, 
            failed: failed.isEmpty ? nil : failed
        )
        if !accepted.isEmpty || !rejected.isEmpty {
            return .ok(.init(body: .json(result)))
        } else {
            return .badRequest(.init(body: .json(result)))
        }
    }

    // MARK: - Question Handling 

    func getRoomQuestionCode(
        _ input: Operations.GetRoomQuestionCode.Input
    ) async throws -> Operations.GetRoomQuestionCode.Output {
        // TODO: Could provide more information to a client, such as a number of votes in the future
        // if an admin token is provided.
        let code = input.path.code
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        guard let questionDescription = await room.currentQuestionDescription else {
            return .badRequest
        }
        return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
    }

    func postRoomQuestionCode(
        _ input: Operations.PostRoomQuestionCode.Input
    ) async throws -> Operations.PostRoomQuestionCode.Output {
        let code = input.path.code
        let adminToken = input.headers.roomAdminToken
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        guard room.verifyAdminToken(adminToken) else {
            return .forbidden
        }
        switch input.body {
            case .json(let question):
                try await room.updateQuestion(
                    prompt: question.prompt, 
                    options: question.options, 
                    style: .init(question.votingStyle)
                )
                // We want to round trip the question to make sure it was created correctly
                guard let questionDescription = await room.currentQuestionDescription else {
                    let reason = "Could not add the question to the room."
                    return .internalServerError(.init(body: .json(.init(reason: reason))))
                }
                return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
        }
    }

    func deleteRoomQuestionCode(
        _ input: Operations.DeleteRoomQuestionCode.Input
    ) async throws -> Operations.DeleteRoomQuestionCode.Output {
        let code = input.path.code
        let adminToken = input.headers.roomAdminToken
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        guard room.verifyAdminToken(adminToken) else {
            return .forbidden
        }
        guard let questionDescription = await room.currentQuestionDescription else {
            return .badRequest
        }
        try await room.removeQuestion()
        return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
    }

    // MARK: - Voting

    func postRoomVoteCodeQuestionID(
        _ input: Operations.PostRoomVoteCodeQuestionID.Input
    ) async throws -> Operations.PostRoomVoteCodeQuestionID.Output {
        let code = input.path.code
        let questionID = input.path.questionID
        let participantToken = input.headers.participantToken
        guard 
            let room = await roomManager.room(withCode: code),
            await questionID == room.currentQuestionDescription?.id.uuidString
        else {
            return .notFound
        }
        guard await room.hasParticipant(withParticipantToken: participantToken) else {
            return .forbidden
        }
        switch input.body {
            case .json(let anyVote):
                do {
                    try await room.registerVote(anyVote, forParticipant: participantToken)
                    return .ok
                } catch let questionError as Question.Error {
                    switch questionError {
                        case .invalidVote, .voteStyleMismatch:
                            return .badRequest
                        default:
                            throw questionError
                    }
                }
                
        }
    }

}
