public protocol RoomCodeGeneratorProtocol: Sendable {
    /// Generates a new room code
    mutating func next() -> String
}

public extension RoomCodeGeneratorProtocol {

    /// Repeatedly generates a room code until valid
    /// 
    /// This function tries to generate a room code until a valid one is produced.
    /// A valid room code is dictated by the `filter`.
    /// 
    /// - Parameter maxTries: The maximum times to invoke the filter. Must be at least `1`.
    /// - Parameter filter: The predicate for the code. `true` indicates a valid code.
    /// 
    /// - Returns: A code or `nil` if it could not be generated.
    mutating func generateRoomCode<E: Error>(
        maxTries: Int = 100,
        filter: (_ candidate: String) throws(E) -> Bool,
    ) throws(E) -> String? {
        precondition(maxTries > 0, "maxTries must be at least 1")
        for _ in 0..<maxTries {
            let candidate = self.next()
            if try filter(candidate) { return candidate }
        }
        return nil
    }

    mutating func generateRoomCode<E: Error>(
        maxTries: Int = 100,
        filter: (_ candidate: String) async throws(E) -> Bool,
    ) async throws(E) -> String? {
        precondition(maxTries > 0, "maxTries must be at least 1")
        for _ in 0..<maxTries {
            let candidate = self.next()
            if try await filter(candidate) { return candidate }
        }
        return nil
    }

}

public struct DefaultRoomCodeGenerator: RoomCodeGeneratorProtocol {
    private var generator: SystemRandomNumberGenerator

    public init() {
        self.generator = SystemRandomNumberGenerator()
    }

    mutating public func next() -> String {
        return String(Int.random(in: 0...999_999, using: &generator))
    }
}
