package protocol RoomManagerProtocol: AnyObject, Sendable {

    /// Returns the room with the specified code
    /// 
    /// - Returns: The room or `nil` if it doesn't exist
    func room(withCode code: String) async -> Room?

    /// Creates a new room
    /// 
    /// - Throws:
    ///     ``RoomError.failedToGenerateCode`` if a valid code
    ///     could not be generated.
    /// 
    /// - Returns: 
    ///     The `code` and `adminToken` for the room.
    ///     This is the only way to get the `adminToken`.
    func createRoom(name: String) async throws -> (code: String, adminToken: String)

}