import Hummingbird


actor InMemoryRoomRepository: RoomRepository {

    /// The maximum times a room code can be generated
    /// 
    /// This is to prevent an infinite loop in the rare case we run
    /// out of room codes.
    static let maxRoomCodeIterations = 100

    private var rooms: [String: FullRoomInfo] = [:]

    func addRoom(name: String) async throws -> FullRoomInfo {

        // Attempt to find an unused room code
        var code: String = ""
        var codegenSuccess: Bool = false
        for _ in 0..<Self.maxRoomCodeIterations {
            code = FullRoomInfo.generateCode()
            guard rooms.index(forKey: code) == nil else { continue }
            codegenSuccess = true
            break
        }

        #warning("TODO: Handle error when codegen fails")

        let room = FullRoomInfo(
            name: name,
            code: code
        )

        assert(codegenSuccess && rooms.index(forKey: code) == nil, "\(#function): Cannot add a new room with an already existing code.")
        rooms[code] = room
        return room
    }

    func findRoom(code: String) async throws -> RoomInfo? {
        return rooms[code]?.publicInfo
    }

    
}