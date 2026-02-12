import Foundation
import OpenAPIRuntime

import VoteHandling

public typealias DefaultRoomHandler = RoomHandler<DefaultRoomManager>

public struct RoomHandler<RoomManager: RoomManagerProtocol>: APIProtocol {

    let roomManager: RoomManager

    public init(roomManager: RoomManager) {
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

    func getRoomCodeInfo(
        _ input: Operations.GetRoomCodeInfo.Input
    ) async throws -> Operations.GetRoomCodeInfo.Output {
        let code = input.path.code
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        return .ok(.init(body: .json(.init(name: room.name, code: room.code, fields: room.fields))))
    }

    // MARK: - Join Requests

    func postRoomCodeJoin(
        _ input: Operations.PostRoomCodeJoin.Input
    ) async throws -> Operations.PostRoomCodeJoin.Output {
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

    func getRoomCodeJoinRequests(
        _ input: Operations.GetRoomCodeJoinRequests.Input
    ) async throws -> Operations.GetRoomCodeJoinRequests.Output {
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

    func postRoomCodeJoinRequests(
        _ input: Operations.PostRoomCodeJoinRequests.Input
    ) async throws -> Operations.PostRoomCodeJoinRequests.Output {
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

    func getRoomCodeQuestion(
        _ input: Operations.GetRoomCodeQuestion.Input
    ) async throws -> Operations.GetRoomCodeQuestion.Output {
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

    func postRoomCodeQuestion(
        _ input: Operations.PostRoomCodeQuestion.Input
    ) async throws -> Operations.PostRoomCodeQuestion.Output {
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

    func deleteRoomCodeQuestionID(
        _ input: Operations.DeleteRoomCodeQuestionID.Input
    ) async throws -> Operations.DeleteRoomCodeQuestionID.Output {
        let code = input.path.code
        let questionID = input.path.questionID
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
        guard questionDescription.id.uuidString == questionID else {
            return .badRequest
        }
        try await room.removeQuestion()
        return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
    }

    func putRoomCodeQuestionID(
        _ input: Operations.PutRoomCodeQuestionID.Input
    ) async throws -> Operations.PutRoomCodeQuestionID.Output {
        let code = input.path.code
        let questionID = input.path.questionID
        let adminToken = input.headers.roomAdminToken
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        guard room.verifyAdminToken(adminToken) else {
            return .forbidden
        }
        guard
            let questionUUID = UUID(uuidString: questionID),
            await room.hasQuestion(with: questionUUID)
        else {
            return .badRequest
        }
        let newState: Question.State
        switch input.body {
            case .json(let body):
                switch body {
                    case .open:
                        newState = .open
                    case .close:
                        newState = .closed
                    case .finalize:
                        newState = .finalized
                }
        }
        do {
            try await room.setCurrentQuestionState(to: newState)
        } catch Room.Error.missingActiveQuestion {
            return .notFound
        } catch Question.Error.illegalStateChange(_, _) {
            return .badRequest
        }
        return .ok
    }

    func getRoomCodeQuestionIDResult(
        _ input: Operations.GetRoomCodeQuestionIDResult.Input
    ) async throws -> Operations.GetRoomCodeQuestionIDResult.Output {
        try await withVerifiedQuestion(input: input) { room, questionUUID in
            guard let currentQuestionState = await room.currentQuestionState else {
                assertionFailure("\(#function): Question exists but currentQuestionState return nil")
                return .undocumented(statusCode: 500, .init())
            }
            guard currentQuestionState == .finalized else {
                return .badRequest(.init(body: .json(.questionNotFinalized(
                    roomCode: room.code, 
                    questionID: input.path.questionID, 
                    currentState: currentQuestionState.openAPIQuestionState
                ))))
            }
            // This should not throw, as we already checked that the question state is finalized
            guard
                let description = await room.currentQuestionDescription,
                let result = try await room.currentQuestionResult,
                let voteCount = await room.currentQuestionVoteCount
            else {
                assertionFailure("\(#function): Question exists and is finalized but has no result")
                return .undocumented(statusCode: 500, .init())
            }
            return .ok(.init(body: .json(.init(
                description: description, 
                voteCount: voteCount, 
                result: result
            ))))
        }
    }

    func getRoomCodeQuestionIDVotesInfo(
        _ input: Operations.GetRoomCodeQuestionIDVotesInfo.Input
    ) async throws -> Operations.GetRoomCodeQuestionIDVotesInfo.Output {
        await withVerifiedQuestionAndAdmin(input: input) { room, _, _ in
            return .ok(.init(body: .json(.init(
                timestamp: Date.now.ISO8601Format(), 
                voteCount: await room.currentQuestionVoteCount ?? 0
            ))))
        }
    }

    // MARK: - Voting

    func postRoomCodeQuestionIDVote(
        _ input: Operations.PostRoomCodeQuestionIDVote.Input
    ) async throws -> Operations.PostRoomCodeQuestionIDVote.Output {
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
