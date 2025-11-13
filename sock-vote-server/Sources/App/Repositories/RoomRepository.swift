import Hummingbird


protocol RoomRepository: Sendable {

    /// Creates a new room with the given name
    func addRoom(name: String) async throws -> FullRoomInfo

    /// Tries to find a room
    /// 
    /// - Parameter token:
    ///     The token to search for the room
    /// 
    /// - Returns:
    ///     A ``RoomInfo`` or `nil` if a room wasn't found
    /// 
    func findRoom(code: String) async throws -> RoomInfo?
    
}