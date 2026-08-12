public import VoteHandling

extension Question.VotingStyle {

  public init(_ votingStyle: Components.Schemas.VotingStyle?) {
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

  public var openAPIVotingStyle: Components.Schemas.VotingStyle? {
    switch self {
    case .plurality: .plurality
    case .preferential: .preferential
    }
  }

}
