import Hummingbird

protocol RoomRepository: Sendable {

    /// Creates a new room with the given name
    ///
    /// - Throws:
    ///     ``RoomCodeError/failedToGenerateCode`` when an available
    ///     code can't be found.
    @discardableResult
    func addRoom(name: String, fields: [String]) async throws -> FullRoomInfo

    /// - Throws:
    ///     ``RoomCodeError/codeNotFound(code:)`` when the room code doesn't
    ///     correspond to a registered room.
    ///
    func roomInfo(forCode: RoomCode) async throws -> RoomInfo
    
}

extension RoomRepository {
    
    func addRoom(name: String) async throws -> FullRoomInfo {
        return try await addRoom(name: name, fields: [])
    }
    
}
