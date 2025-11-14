import Foundation


enum RoomCode {

    /// The type used for a room code
    typealias Code = String

    /// The format for the string representation of a code
    static let codeFormat = IntegerFormatStyle<Int>().precision(.integerLength(6))
 
    /// Creates a new room code
    protocol Generator {

        /// The maximum amount of times to retry generation
        var limit: Int { get }

        /// Creates a new room code
        mutating func next() -> String

    }

    struct DefaultGenerator: Generator, Sendable {

        var limit: Int { 100 }

        func next() -> String {
            let number = Int.random(in: 0..<1_000_000)
            return number.formatted(RoomCode.codeFormat)
        }

    }

}




