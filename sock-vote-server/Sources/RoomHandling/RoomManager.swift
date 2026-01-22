import Foundation

package final actor DefaultRoomManager<
    RoomCodeGenerator: RoomCodeGeneratorProtocol
>: RoomManagerProtocol {
    private var rooms: [String : Room]
    
    private var roomCodeGenerator: RoomCodeGenerator
    private var codeGenMaxTries: Int

    init(
        roomCodeGenerator: RoomCodeGenerator = DefaultRoomCodeGenerator(),
        codeGenMaxTries: Int = 100
    ) {
        self.rooms = [:]
        self.roomCodeGenerator = roomCodeGenerator
        self.codeGenMaxTries = codeGenMaxTries
    }

}

package extension DefaultRoomManager {

    func room(
        withCode code: String
    ) -> Room? {
        return rooms[code]
    }

    func createRoom(
        name: String,
    ) throws -> (code: String, adminToken: String) {
        guard let code = roomCodeGenerator.generateRoomCode(
            maxTries: codeGenMaxTries, 
            filter: { !rooms.keys.contains($0) }
        ) else {
            throw RoomError.failedToGenerateCode
        }
        // TODO: Find a more secure way to generate admin tokens
        let adminToken = UUID().uuidString
        let room = Room(name: name, code: code, adminToken: adminToken)
        assert(!rooms.keys.contains(code))
        rooms[code] = room
        return (code: code, adminToken: adminToken)
    }

}