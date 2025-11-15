import Foundation
import Hummingbird

enum Room {

    /// The type used for a room code
    typealias Code = String
    
    /// The type of the token used for authentication
    typealias Token = String

    /// The format for the string representation of a code
    static let codeFormat = IntegerFormatStyle<Int>().precision(.integerLength(6)).grouping(.never)

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
        ///     ``RoomError/FailedToGenerateCode`` if the generator runs out of tries.
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
