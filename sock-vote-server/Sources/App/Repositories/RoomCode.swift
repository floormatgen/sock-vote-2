import Foundation

enum RoomCode {

    /// The type used for a room code
    typealias Code = String

    typealias FailedToGenerateError = RoomError.FailedToGenerateCode

    /// The format for the string representation of a code
    static let codeFormat = IntegerFormatStyle<Int>().precision(.integerLength(6)).grouping(.never)

    /// Creates a new room code
    protocol Generator {

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

    struct DefaultGenerator: Generator, Sendable {

        var limit: Int { 100 }

        func next() -> Code {
            let number = Int.random(in: 0..<1_000_000)
            return number.formatted(RoomCode.codeFormat)
        }

    }

}

extension RoomCode.Generator {

    mutating func generationLoop(
        validation: (_ code: RoomCode.Code) throws -> Bool
    ) throws -> RoomCode.Code {
        for _ in 0..<self.limit {
            let code = self.next()
            guard try validation(code) else { continue }
            return code
        }
        throw RoomCode.FailedToGenerateError()
    }


}
