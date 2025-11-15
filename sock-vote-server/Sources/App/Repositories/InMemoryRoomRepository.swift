import Hummingbird

actor InMemoryRoomRepository<Generator: Room.CodeGenerator>: RoomRepository {

    var generator: Generator

    init(generator: Generator) {
        self.generator = generator
    }

    init() where Generator == Room.DefaultCodeGenerator {
        self.generator = Room.DefaultCodeGenerator()
    }

    private var rooms: [String: Room.FullInfo] = [:]

    func addRoom(name: String) async throws -> Room.FullInfo {

        // Attempt to find an unused room code
        let code = try generator.generationLoop { rooms.index(forKey: $0) == nil } 

        let room = Room.FullInfo(
            name: name,
            code: code
        )

        rooms[code] = room
        return room
    }
 
    func findRoom(code: String) async throws -> Room.Info {
        guard let roomInfo = rooms[code]?.publicInfo else {
            throw Room.Error.CodeNotFound(code: code)
        }

        return roomInfo
    }

}
