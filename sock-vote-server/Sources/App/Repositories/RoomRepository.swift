import Hummingbird


protocol RoomRepository: Sendable {

    /// Creates a new room with the given name
    /// 
    /// - Throws:
    ///     ``RoomErrors/FailedToGenerateCode`` when an available
    ///     code can't be found.
    func addRoom(name: String) async throws -> FullRoomInfo

    /// - Throws: 
    ///     ``RoomErrors/NotFound`` when the room code doesn't 
    ///     correspond to a registered room.
    /// 
    func findRoom(code: String) async throws -> RoomInfo
    
}
