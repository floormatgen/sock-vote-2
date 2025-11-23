import Foundation
import Hummingbird

/// A Room Manager that manages rooms in-memory, in-process
actor InMemoryRoomManager<Participant: ParticipantProtocol, CodeGenerator: RoomCodeGenerator>: RoomRepository {

    /// The rooms that the manager manages
    private var rooms: [RoomCode : InMemoryRoom<Participant>] = [:]
    
    /// A generator to create codes
    private var generator: CodeGenerator

    /// A function that returns when a timeout
    /// 
    /// When a room becomes alive again, the task containing this function will be cancelled.
    /// Most implementations should rethrow the `CancellationError`.
    private let timeoutFunction: @Sendable () async throws -> Void

    /// Current timeouts for 'dead' rooms
    /// 
    /// If a room because alive, due to a call to ``didBecomeAlive(code:)``
    private var roomTimeouts: [RoomCode : Task<Void, any Error>] = [:]
    
    init(
        participants: Participant.Type = WebSocketParticipant.self,
        generator: CodeGenerator = DefaultRoomCodeGenerator(),
        timeoutFunction: @Sendable @escaping () async throws -> Void
    ) {
        self.generator = generator
        self.timeoutFunction = timeoutFunction
    }

    init(timeout: Duration = .seconds(45)) where Participant == WebSocketParticipant, CodeGenerator == DefaultRoomCodeGenerator {
        self.init(timeoutFunction: { try await Task.sleep(for: timeout) })
    }

    // MARK: - Room Repository
    
    func addRoom(name: String, fields: [String]) async throws -> FullRoomInfo {
        let code = try generator.generationLoop(validation: { rooms.index(forKey: $0) == nil })
        #warning("TODO: Find a more secure way to generate a token")
        let token = UUID().uuidString
        let room = InMemoryRoom<Participant>(name: name, code: code, fields: fields, roomToken: token)

        // Add the room to the currently listed tracked rooms
        rooms[code] = room
        if await !room.isAlive { schedulePurge(forCode: code) }
        return room.fullInfo
    }
    
    func findRoom(code: RoomCode) async throws -> RoomInfo {
        guard let room = rooms[code] else {
            throw RoomCodeError.codeNotFound(code: code)
        }
        return room.info
    }

    // MARK: - Room Actions

    func didBecomeAlive(code: RoomCode) async throws {
        roomTimeouts[code]?.cancel()
        roomTimeouts[code] = nil
    }

    func didBecomeInactive(code: RoomCode) async throws {
        schedulePurge(forCode: code)
    }

    private func schedulePurge(forCode code: RoomCode) {
        // If the room is not alive, start the timeout
        roomTimeouts[code] = Task {
            try await timeoutFunction()
        }
    }
    
}

