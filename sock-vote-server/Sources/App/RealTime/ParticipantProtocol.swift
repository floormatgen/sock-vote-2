import Hummingbird
import Foundation

protocol ParticipantProtocol: Sendable, Equatable, Identifiable {
    
    /// The room that 'owns' the participant
    ///
    /// When implementing a ``ParticipantProtocol``, it should be assumed that this property
    /// is set by the owning room after it is added. This is so room operations can be performed on it.
    var room: (any RoomProtocol)? { get set }
    
    /// A unique id that identifies each participant
    ///
    /// > Precondition:
    /// > This is unique for each participant in a room.
    var id: UUID { get }

    /// The name of the participant
    /// 
    /// > Note:
    /// > This doesn't need to be unqiue, only the ``id`` needs to be.
    var name: String { get }

    /// The additional information provided by the participant
    /// 
    /// If there is no additional information, this should be equal
    /// to the empty dictionary.
    var fields: [String : String] { get }
    
    /// Whether the participant is active
    ///
    /// For example, this returns `true` for a ``WebSocketParticipant`` when there is a participant
    /// backing the connection.
    ///
    /// This property can be used as a grace period, such as when someone disconnects due
    /// to a flaky internet connection.
    var isAlive: Bool { get }
    
}

extension ParticipantProtocol {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

}
