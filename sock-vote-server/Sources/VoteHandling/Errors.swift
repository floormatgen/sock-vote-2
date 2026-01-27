extension Question {

    public enum Error: Swift.Error, Sendable {
        /// The vote style received was incorrect
        case voteStyleMismatch(expected: VotingStyle, received: VotingStyle)

        var localizedDescription: String {
            switch self {
                case let .voteStyleMismatch(expected, received):
                    "Invalid vote: expected \(expected) vote but instead got \(received) vote."
            }
        }
    }

}