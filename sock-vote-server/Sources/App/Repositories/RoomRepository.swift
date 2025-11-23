import Hummingbird

protocol RoomRepository: Sendable {

    /// Creates a new room with the given name
    ///
    /// - Throws:
    ///     ``Room/Error/FailedToGenerateCode`` when an available
    ///     code can't be found.
    func addRoom(name: String, fields: [String]) async throws -> FullRoomInfo

    /// - Throws:
    ///     ``Room/Error/CodeNotFound`` when the room code doesn't
    ///     correspond to a registered room.
    ///
    func findRoom(code: RoomCode) async throws -> RoomInfo
    
}

extension RoomRepository {
    
    func addRoom(name: String) async throws -> FullRoomInfo {
        return try await addRoom(name: name, fields: [])
    }
    
}
