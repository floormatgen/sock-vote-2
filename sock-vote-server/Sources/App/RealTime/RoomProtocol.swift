import Foundation
import Hummingbird

protocol RoomProtocol: Sendable, Equatable, Identifiable, AnyObject {
    associatedtype Participant: ParticipantProtocol

    /// The room manager managing the room
    /// 
    /// This property will be set by the room manager
    var manager: (any RoomManagerProtocol)? { get set }

    // MARK: - Room Information

    /// The name of the room
    var name: String { get }
    
    /// The code to use in order to gain access to the room
    var code: RoomCode { get }
    
    /// The token needed by users to do special actions
    var roomToken: RoomToken { get }

    /// Whether the room is alive
    /// 
    /// When the status changes, the room is expected to call
    var isAlive: Bool { get async }

}

// MARK: - Utility

extension RoomProtocol {
    
    var info: RoomInfo {
        return RoomInfo(name: name, code: code)
    }
    
    var fullInfo: FullRoomInfo {
        return FullRoomInfo(name: name, code: code, token: roomToken)
    }
    
}

// MARK: - Builtin conformances

extension RoomProtocol {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        // Rooms should be uniquely identifiable by their code
        return lhs.code == rhs.code
    }
    
    var id: RoomCode { code }
    
}
