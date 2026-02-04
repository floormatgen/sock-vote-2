extension Question {

    public enum Error: Swift.Error, Sendable, Equatable {
        /// A room must have at least one selectable option
        case noOptions
        /// The vote style received was incorrect
        case voteStyleMismatch(expected: VotingStyle, received: VotingStyle)
        /// The vote is ill-formed
        /// 
        /// This can be thrown when a vote is added to a quesiton, 
        /// or (should not happen) when calculating the result and an invalid vote is detected
        case invalidVote
        /// The question is not in the correct state to perform this action
        case illegalAction(required: State, current: State)
        /// Changing from the `current` to the `new` state is not allowed
        case illegalStateChange(current: State, new: State)

        var localizedDescription: String {
            switch self {
                case .noOptions:
                    "A room must have at least one selectable option."
                case let .voteStyleMismatch(expected, received):
                    "Invalid vote: expected \(expected) vote but instead got \(received) vote."
                case .invalidVote:
                    "Vote is ill-formed."
                case let .illegalAction(required, current):
                    "This action cannot be performed while the question is in the \(current) state, it must be in the \(required) state."
                case let .illegalStateChange(current, new):
                    "Changing from the \(current) state to the \(new) state is not allowed."
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
