extension Question {

    package enum Error: Swift.Error {
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