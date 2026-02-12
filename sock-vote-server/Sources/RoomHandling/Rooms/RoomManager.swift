import Foundation
import ServiceLifecycle

public protocol RoomManagerProtocol: Actor, Sendable, Service {
    associatedtype Room: RoomProtocol = DefaultRoom

    /// Returns the room with the specified code
    /// 
    /// - Returns: The room or `nil` if it doesn't exist
    func room(withCode code: String) -> Room?

    /// Creates a new room
    /// 
    /// - Throws:
    ///     ``RoomError/failedToGenerateCode`` if a valid code
    ///     could not be generated.
    /// 
    /// - Returns: 
    ///     The `code` and `adminToken` for the room.
    ///     This is the only way to get the `adminToken`.
    func createRoom(name: String, fields: [String]) throws -> (code: String, adminToken: String)

    /// Whether the room manager is allowing new rooms to be registered
    /// 
    /// This property reuturns `true` after `run()` is called,
    /// and can start returning `false` after task cancellation or graceful shutdown is triggered
    /// on `run()`.
    var isAcceptingNewRooms: Bool { get }

}

public typealias DefaultRoomManager = RoomManager<DefaultRoom, DefaultRoomCodeGenerator>

public final actor RoomManager<
    Room: RoomProtocol,
    RoomCodeGenerator: RoomCodeGeneratorProtocol
>: RoomManagerProtocol {
    private var rooms: [String : Room]
    
    private var roomCodeGenerator: RoomCodeGenerator
    private var codeGenMaxTries: Int

    public private(set) var isAcceptingNewRooms: Bool

    public init(
        roomType: Room.Type = Room.self,
        roomCodeGenerator: RoomCodeGenerator = DefaultRoomCodeGenerator(),
        codeGenMaxTries: Int = 100
    ) {
        self.rooms = [:]
        self.roomCodeGenerator = roomCodeGenerator
        self.codeGenMaxTries = codeGenMaxTries

        let (connectionSequence, connectionSequenceContinuation) = ConnectionSequence.makeStream()
        self.connectionSequence = connectionSequence
        self.connectionSequenceContinuation = connectionSequenceContinuation

        self.isAcceptingNewRooms = false
    }

    private typealias ConnectionSequence = AsyncStream<@Sendable () async throws -> Void>
    private nonisolated let connectionSequence: ConnectionSequence
    private nonisolated let connectionSequenceContinuation: ConnectionSequence.Continuation

    public func run() async throws {
        isAcceptingNewRooms = true
        // Graceful shutdown and task cancellation are handled by
        // connection managers
        try await withTaskCancellationOrGracefulShutdownHandler {
            try await withThrowingDiscardingTaskGroup { group in
                for await connection in self.connectionSequence {
                    group.addTask {
                        try await connection()
                    }
                }
            }    
        } onCancelOrGracefulShutdown: {
            self.connectionSequenceContinuation.finish()
            // TODO: Try not using an unstructured task here
            Task { await self._setIsAcceptingNewRooms(false) }
        }
        isAcceptingNewRooms = false
    }

    private func _setIsAcceptingNewRooms(_ newValue: Bool) {
        self.isAcceptingNewRooms = newValue
    }

}

public extension RoomManager {

    func room(
        withCode code: String
    ) -> Room? {
        return rooms[code]
    }

    func createRoom(
        name: String, fields: [String]
    ) throws -> (code: String, adminToken: String) {
        guard isAcceptingNewRooms else {
            throw RoomManagerError.managerNotAcceptingNewRooms
        }
        guard let code = roomCodeGenerator.generateRoomCode(
            maxTries: codeGenMaxTries, 
            filter: { !rooms.keys.contains($0) }
        ) else {
            throw RoomError.failedToGenerateCode
        }
        // TODO: Find a more secure way to generate admin tokens
        let adminToken = UUID().uuidString
        // TODO: Allow configuring the timeouts
        let room = Room(
            name: name, 
            code: code, 
            fields: fields, 
            adminToken: adminToken,
            participantTimeout: .seconds(45),
            joinRequestTimeout: .seconds(120)
        )
        connectionSequenceContinuation.yield {
            try await room.runConnectionManager()
        }
        assert(!rooms.keys.contains(code))
        rooms[code] = room
        return (code: code, adminToken: adminToken)
    }

}
