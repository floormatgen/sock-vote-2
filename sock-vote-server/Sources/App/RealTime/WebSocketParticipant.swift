import Foundation
import Hummingbird
import HummingbirdWebSocket

/// A participant backed by a websocket connection
struct WebSocketParticipant: ParticipantProtocol {
    weak var room: (any RoomProtocol)?

    let name: String
    let id: UUID
    let fields: Fields
    let joined: Date

    /// Whether the participant curerntly has a websocket backing it
    ///
    /// A new  ``WebSocketParticipant`` starts inactive, as it requires a websocket to back it.
    var isAlive: Bool = false

    private var inbound: WebSocketInboundStream?
    private var outbound: WebSocketOutboundWriter?

    init(name: String, id: UUID, fields: Fields, joined: Date = .now) {
        self.name = name
        self.id = id
        self.fields = fields
        self.joined = joined
    }

}
