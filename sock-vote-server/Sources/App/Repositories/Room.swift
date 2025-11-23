import Foundation
import Hummingbird

/// The type used for a room code
typealias RoomCode = String

/// The type of the token used for authentication
typealias RoomToken = String

/// A list of additional information given about a participant
typealias Fields = [String : String]

/// The format for the string representation of a code
let roomCodeFormat = IntegerFormatStyle<Int>().precision(.integerLength(6)).grouping(.never)

// MARK: - Code Generation

/// Creates a new room code
protocol RoomCodeGenerator {

    /// The maximum amount of times to retry generation
    var limit: Int { get }

    /// Creates a new room code
    mutating func next() -> RoomCode

    /// Attempts to create a validated code
    ///
    /// This function tries up to ``limit`` times to create a valid code.
    ///
    /// - Parameter validation:
    ///     The closure to check if a code is valid
    ///
    /// - Throws:
    ///     ``Room/Error/FailedToGenerateCode`` if the generator runs out of tries.
    mutating func generationLoop(
        validation: (_ code: RoomCode) throws -> Bool
    ) throws -> RoomCode

}

struct DefaultRoomCodeGenerator: RoomCodeGenerator, Sendable {

    var limit: Int { 100 }

    func next() -> RoomCode {
        let number = Int.random(in: 0..<1_000_000)
        return number.formatted(roomCodeFormat)
    }

}
    

extension RoomCodeGenerator {

    mutating func generationLoop(
        validation: (_ code: RoomCode) throws -> Bool
    ) throws -> RoomCode {
        for _ in 0..<self.limit {
            let code = self.next()
            guard try validation(code) else { continue }
            return code
        }
        throw RoomCodeError.failedToGenerateCode
    }

}

// MARK: - Room Info
    
/// Information about a Room
struct RoomInfo {
    /// The name of a room
    let name: String
    /// The code of a room
    let code: RoomCode
}

struct FullRoomInfo {
    let name: String
    let code: RoomCode
    /// The private token to configure the room
    let token: String
    
    init(name: String, code: RoomCode, token: RoomToken) {
        self.name   = name
        self.code   = code
        self.token  = token
    }

    /// Provides the public information about the room
    ///
    /// ``Room/FullInfo`` contains the ``token``,
    /// which should not be shared publicly.
    var publicInfo: RoomInfo {
        return RoomInfo(
            name: self.name,
            code: self.code
        )
    }
}

extension RoomInfo: ResponseCodable, Equatable, Hashable, Sendable {}
extension FullRoomInfo: ResponseCodable, Equatable, Hashable, Sendable {}

// MARK: - Errors

enum RoomCodeError: HTTPResponseError, Equatable {
    /// Thrown when a room isn't found
    case codeNotFound(code: String)
    /// Thrown when a code can't be found for a room
    case failedToGenerateCode

    var status: HTTPResponse.Status {
        switch self {
        case .codeNotFound(_):
            return .notFound
        case .failedToGenerateCode:
            return .internalServerError
        }
    }

    func response(from request: Request, context: some RequestContext) throws -> Response {
        return Response(status: self.status)
    }

}
