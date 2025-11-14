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
        var code: String = ""
        var codegenSuccess: Bool = false
        for _ in 0..<generator.limit {
            code = generator.next()
            guard rooms.index(forKey: code) == nil else { continue }
            codegenSuccess = true
            break
        }

        guard codegenSuccess else {
            throw RoomError.FailedToGenerateCode()
        }

        let room = FullRoomInfo(
            name: name,
            code: code
        )

        assert(codegenSuccess && rooms.index(forKey: code) == nil, "\(#function): Cannot add a new room with an already existing code.")
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
