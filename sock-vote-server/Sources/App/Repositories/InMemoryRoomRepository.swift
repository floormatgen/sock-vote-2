import Hummingbird

actor InMemoryRoomRepository<Generator: RoomCode.Generator>: RoomRepository {

    var generator: Generator

    init(generator: Generator) {
        self.generator = generator
    }

    init() where Generator == RoomCode.DefaultGenerator {
        self.generator = RoomCode.DefaultGenerator()
    }

    private var rooms: [String: FullRoomInfo] = [:]

    func addRoom(name: String) async throws -> FullRoomInfo {

        // Attempt to find an unused room code
        let code = try generator.generationLoop { rooms.index(forKey: $0) == nil } 

        let room = FullRoomInfo(
            name: name,
            code: code
        )

        rooms[code] = room
        return room
    }

    func findRoom(code: String) async throws -> RoomInfo {
        guard let roomInfo = rooms[code]?.publicInfo else {
            throw RoomError.NotFound(code: code)
        }

        return roomInfo
    }

}
