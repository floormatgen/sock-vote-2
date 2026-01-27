import Foundation

public protocol RoomManagerProtocol: AnyObject, Sendable {
    associatedtype Room: RoomProtocol = DefaultRoom

    /// Returns the room with the specified code
    /// 
    /// - Returns: The room or `nil` if it doesn't exist
    func room(withCode code: String) async -> Room?

    /// Creates a new room
    /// 
    /// - Throws:
    ///     ``RoomError/failedToGenerateCode`` if a valid code
    ///     could not be generated.
    /// 
    /// - Returns: 
    ///     The `code` and `adminToken` for the room.
    ///     This is the only way to get the `adminToken`.
    func createRoom(name: String, fields: [String]) async throws -> (code: String, adminToken: String)

}

public final actor DefaultRoomManager<
    RoomCodeGenerator: RoomCodeGeneratorProtocol
>: RoomManagerProtocol {
    private var rooms: [String : Room]
    
    private var roomCodeGenerator: RoomCodeGenerator
    private var codeGenMaxTries: Int

    public init(
        roomCodeGenerator: RoomCodeGenerator = DefaultRoomCodeGenerator(),
        codeGenMaxTries: Int = 100
    ) {
        self.rooms = [:]
        self.roomCodeGenerator = roomCodeGenerator
        self.codeGenMaxTries = codeGenMaxTries
    }

}

public extension DefaultRoomManager {

    func room(
        withCode code: String
    ) -> Room? {
        return rooms[code]
    }

    func createRoom(
        name: String, fields: [String]
    ) throws -> (code: String, adminToken: String) {
        guard let code = roomCodeGenerator.generateRoomCode(
            maxTries: codeGenMaxTries, 
            filter: { !rooms.keys.contains($0) }
        ) else {
            throw RoomError.failedToGenerateCode
        }
        // TODO: Find a more secure way to generate admin tokens
        let adminToken = UUID().uuidString
        let room = Room(name: name, code: code, fields: fields, adminToken: adminToken)
        assert(!rooms.keys.contains(code))
        rooms[code] = room
        return (code: code, adminToken: adminToken)
    }

}