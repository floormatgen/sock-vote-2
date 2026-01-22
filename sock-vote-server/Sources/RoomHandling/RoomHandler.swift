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
                } catch let error as RoomError where error == .failedToGenerateCode {
                    return .internalServerError(.init(body: .json(.init(reason: error.localizedDescription))))
                }
        }
    }

    func getRoomInfoCode(
        _ input: Operations.GetRoomInfoCode.Input
    ) async throws -> Operations.GetRoomInfoCode.Output {
        let code = input.path.code
        guard let room = await roomManager.room(withCode: code) else {
            return .notFound(.init())
        }
        return .ok(.init(body: .json(.init(name: room.name, code: room.code))))
    }

    func postRoomJoinCode(
        _ input: Operations.PostRoomJoinCode.Input
    ) async throws -> Operations.PostRoomJoinCode.Output {
        fatalError()
    }

}