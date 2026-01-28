extension Question {

    public enum Error: Swift.Error, Sendable, Equatable {
        /// A room must have at least one selectable option
        case noOptions
        /// The vote style received was incorrect
        case voteStyleMismatch(expected: VotingStyle, received: VotingStyle)
        /// The vote is ill-formed
        case invalidVote

        var localizedDescription: String {
            switch self {
                case .noOptions:
                    "A room must have at least one selectable option."
                case let .voteStyleMismatch(expected, received):
                    "Invalid vote: expected \(expected) vote but instead got \(received) vote."
                case .invalidVote:
                    "Vote is ill-formed."
            }
        }
    }

}

// extension Question.Error: Equatable {

//     public static func == (lhs: Self, rhs: Self) -> Bool {
//         switch (lhs, rhs) {
//             case let (.voteStyleMismatch(le, lr), .voteStyleMismatch(expected: re, received: rr)):
//                 return (le == re) && (lr == rr) 
//         }
//     }

// }
