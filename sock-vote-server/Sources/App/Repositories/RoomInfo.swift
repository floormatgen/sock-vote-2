import Foundation
import Hummingbird


/// Information about a Room
struct RoomInfo {
    /// The name of a room
    let name: String
    /// The code of a room
    let code: RoomCode.Code
}

struct FullRoomInfo {
    let name: String
    let code: RoomCode.Code
    /// The private token to configure the room
    let token: String

    /// Creates a new roomInfo
    init(name: String, code: RoomCode.Code) {
        self.name = name
        self.code = code
        #warning("TODO: There are likely more secure ways of making tokens instead of using UUIDs.")
        self.token = UUID().uuidString
    }

    /// Provides the public information about the room
    /// 
    /// ``FullRoomInfo`` contains the ``token``,
    /// which should not be shared publicly.
    var publicInfo: RoomInfo {
        return RoomInfo(
            name: self.name,
            code: self.code
        )
    }
}

extension RoomInfo:     ResponseCodable, Equatable, Hashable, Sendable { }
extension FullRoomInfo: ResponseCodable, Equatable, Hashable, Sendable { }
