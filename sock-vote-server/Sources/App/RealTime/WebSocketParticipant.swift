import Foundation
import Hummingbird
import HummingbirdWebSocket

/// A participant backed by a websocket connection
struct WebSocketParticipant: ParticipantProtocol {
    weak var room: (any RoomProtocol)?

    let name: String
    let id: UUID
    let fields: Fields

    /// Whether the participant curerntly has a websocket backing it
    var isAlive: Bool = false

    var inbound: WebSocketInboundStream?
    var outbound: WebSocketOutboundWriter?

    init(name: String, id: UUID, fields: Fields) {
        self.name = name
        self.id = id
        self.fields = fields
    }

}
