import VoteHandling

public extension Question.State {

    init(_ openAPIQuestionState: Components.Schemas.QuestionState) {
        switch openAPIQuestionState {
            case .open: self = .open
            case .closed: self = .closed
            case .finalized: self = .finalized
        }
    }

    var openAPIQuestionState: Components.Schemas.QuestionState {
        .init(rawValue: description)!
    }

}
