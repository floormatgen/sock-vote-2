import Foundation
import OpenAPIRuntime

package typealias DefaultRoomHandler = RoomHandler<DefaultRoomManager<DefaultRoomCodeGenerator>>

package struct RoomHandler<RoomManager: RoomManagerProtocol>: APIProtocol {

    let roomManager: RoomManager

    package init(roomManager: RoomManager = DefaultRoomManager()) {
        self.roomManager = roomManager
    }

}

package extension RoomHandler {

    func postRoomCreate(
        _ input: Operations.PostRoomCreate.Input
    ) async throws -> Operations.PostRoomCreate.Output {
        switch input.body {
            case .json(let roomCreationRequest):
                do {
                    let name = roomCreationRequest.name
                    let (code, adminToken) = try await roomManager.createRoom(name: name)
                    return .ok(.init(body: .json(.init(name: name, code: code, adminToken: adminToken))))
                } catch let error as RoomError where .failedToGenerateCode == error {
                    return .internalServerError(.init(body: .json(.init(reason: error.localizedDescription))))
                }
        }
    }

    func getRoomInfoCode(
        _ input: Operations.GetRoomInfoCode.Input
    ) async throws -> Operations.GetRoomInfoCode.Output {
        let code = input.path.code
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound
        }
        return .ok(.init(body: .json(.init(name: room.name, code: room.code))))
    }

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
                    case .rejected:
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
            requests: await room.joinRequests.map {
                let outFields = $0.1.fields.isEmpty 
                    ? nil 
                    : Components.Schemas.Fields(additionalProperties: $0.1.fields)
                return .init(
                    name: $0.1.name,
                    participantToken: $0.0,
                    timestamp: $0.1.timestamp.ISO8601Format(),
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
        if failed.isEmpty {
            return .ok(.init(body: .json(result)))
        } else if !accepted.isEmpty || !rejected.isEmpty {
            return .code207(.init(body: .json(result)))
        } else {
            return .badRequest(.init(body: .json(result)))
        }
    }

}