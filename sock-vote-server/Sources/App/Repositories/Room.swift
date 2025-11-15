import Foundation
import Hummingbird

/// A `namespace` for Room-related symbols
enum Room {

    /// The type used for a room code
    typealias Code = String
    
    /// The type of the token used for authentication
    typealias Token = String

    /// The format for the string representation of a code
    static let codeFormat = IntegerFormatStyle<Int>().precision(.integerLength(6)).grouping(.never)

}

// MARK: - Code Generation

extension Room {
    
    /// Creates a new room code
    protocol CodeGenerator {

        /// The maximum amount of times to retry generation
        var limit: Int { get }

        /// Creates a new room code
        mutating func next() -> Code

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
            validation: (_ code: Code) throws -> Bool
        ) throws -> Code

    }

    struct DefaultCodeGenerator: CodeGenerator, Sendable {

        var limit: Int { 100 }

        func next() -> Code {
            let number = Int.random(in: 0..<1_000_000)
            return number.formatted(Room.codeFormat)
        }

    }
    
}

extension Room.CodeGenerator {

    mutating func generationLoop(
        validation: (_ code: Room.Code) throws -> Bool
    ) throws -> Room.Code {
        for _ in 0..<self.limit {
            let code = self.next()
            guard try validation(code) else { continue }
            return code
        }
        throw Room.Error.FailedToGenerateCode()
    }

}

// MARK: - Room Info

extension Room {
    
    /// Information about a Room
    struct Info {
        /// The name of a room
        let name: String
        /// The code of a room
        let code: Room.Code
    }

    struct FullInfo {
        let name: String
        let code: Room.Code
        /// The private token to configure the room
        let token: String

        /// Creates a new roomInfo
        init(name: String, code: Room.Code) {
            self.name = name
            self.code = code
            #warning("TODO: There are likely more secure ways of making tokens instead of using UUIDs.")
            self.token = UUID().uuidString
        }

        /// Provides the public information about the room
        ///
        /// ``Room/FullInfo`` contains the ``token``,
        /// which should not be shared publicly.
        var publicInfo: Info {
            return Info(
                name: self.name,
                code: self.code
            )
        }
    }
    
}

extension Room.Info: ResponseCodable, Equatable, Hashable, Sendable {}
extension Room.FullInfo: ResponseCodable, Equatable, Hashable, Sendable {}

// MARK: - Errors

extension Room {
    
    enum Error {
        
        /// Thrown when a room isn't found
        struct CodeNotFound: HTTPResponseError {

            var code: String

            var status: HTTPResponse.Status { .notFound }

            init(code: String) {
                self.code = code
            }

            func response(from request: Request, context: some RequestContext) throws -> Response {
                return Response(status: self.status)
            }
        }
     
        /// Thrown when a code can't be found for a room
        struct FailedToGenerateCode: HTTPResponseError {

            var status: HTTPResponse.Status { .internalServerError }

            func response(from request: Request, context: some RequestContext) throws -> Response {
                return Response(status: self.status)
            }

        }
        
    }

}
