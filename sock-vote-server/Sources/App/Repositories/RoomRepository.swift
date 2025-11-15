import Hummingbird


protocol RoomRepository: Sendable {

    /// Creates a new room with the given name
    /// 
    /// - Throws:
    ///     ``Room/Error/FailedToGenerateCode`` when an available
    ///     code can't be found.
    func addRoom(name: String) async throws -> Room.FullInfo

    /// - Throws: 
    ///     ``Room/Error/CodeNotFound`` when the room code doesn't
    ///     correspond to a registered room.
    /// 
    func findRoom(code: String) async throws -> Room.Info
    
}
