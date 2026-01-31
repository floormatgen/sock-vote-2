import VoteHandling

public extension Question.VotingStyle {

    init(_ votingStyle: Components.Schemas.VotingStyle?) {
        switch votingStyle {
            case .plurality: 
                self = .plurality
            case .preferential: 
                self = .preferential
            case .none:
                // Plurality is the default voting style
                self = .plurality
        }
    }

    var openAPIVotingStyle: Components.Schemas.VotingStyle? {
        switch self {
            case .plurality: .plurality
            case .preferential: .preferential
        }
    }

}
