public import VoteHandling

extension Question.State {

  public init(_ openAPIQuestionState: Components.Schemas.QuestionState) {
    switch openAPIQuestionState {
    case .open: self = .open
    case .closed: self = .closed
    case .finalized: self = .finalized
    }
  }

  public var openAPIQuestionState: Components.Schemas.QuestionState {
    .init(rawValue: description)!
  }

}
