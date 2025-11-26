import Foundation
import Hummingbird

actor InMemoryRoom<Participant: ParticipantProtocol>: RoomProtocol {

    #warning("TODO: Account for admin user(s).")

    /// The manager that manages this room
    /// 
    /// This is marked `nonisolated(unsafe)` as this 
    /// property should only be set once by the roomManager.
    nonisolated(unsafe) var manager: (any RoomManagerProtocol)?

    /// The current participants in a room
    var participants: [UUID : Participant] = [:]

    var isAlive: Bool = false

    let name: String
    let code: RoomCode
    let fields: [String]
    let roomToken: RoomToken

    init(name: String, code: RoomCode, fields: [String], roomToken: RoomToken) {
        self.name = name
        self.code = code
        self.fields = fields
        self.roomToken = roomToken
    }

}
