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
        }
        
        // let result = try await room.requestJoinRoom(name: , fields: [String : String])
        fatalError()
    }

    func getRoomJoinRequestsCode(
        _ input: Operations.GetRoomJoinRequestsCode.Input
    ) async throws -> Operations.GetRoomJoinRequestsCode.Output {
        fatalError()
    }

    func postRoomJoinRequestsCode(
        _ input: Operations.PostRoomJoinRequestsCode.Input
    ) async throws -> Operations.PostRoomJoinRequestsCode.Output {
        fatalError()
    }

}