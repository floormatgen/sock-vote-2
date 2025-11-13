import Foundation
import Hummingbird


/// Information about a Room
struct RoomInfo {
    /// The name of a room
    let name: String
    /// The code of a room
    let code: String
}

struct FullRoomInfo {
    let name: String
    let code: String
    /// The private token to configure the room
    let token: String

    /// Creates a new roomInfo
    init(name: String, code: String) {
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

extension RoomInfo: ResponseCodable, Equatable, Hashable, Sendable { }
extension FullRoomInfo: ResponseCodable, Equatable, Hashable, Sendable { }


// MARK: - Code Generation

extension FullRoomInfo {

    /// The format for the string representation of a code
    static let codeFormat = IntegerFormatStyle<Int>().precision(.integerLength(6))

    /// Generates a random room code
    static func generateCode() -> String {
        var random = SystemRandomNumberGenerator()
        return generateCode(using: &random)
    }

    /// Generates a random room code
    static func generateCode(
        using random: inout some RandomNumberGenerator
    ) -> String {
        return codeFormat.format(Int.random(in: 0..<1_000_000, using: &random))
    }

}