import VoteHandling

extension Question.Result {

    var openAPIQuestionResult: Components.Schemas.QuestionResult {
        switch self {
            case .singleWinner(let winner):
                return .singleWinner(.init(
                    value1: .init(
                        _type: .singleWinner
                    ), 
                    value2: .init(
                        winner: winner
                    )
                ))
            case .tie(let winners):
                return .tie(.init(
                    value1: .init(
                        _type: .tie
                    ), 
                    value2: .init(
                        winners: winners
                    )
                ))
            case .noVotes:
                return .noVotes(.init(
                    value1: .init(
                        _type: .noVotes
                    )
                ))
        }
    }

    init(_ openAPIQuestionResult: Components.Schemas.QuestionResult) {
        switch openAPIQuestionResult {
            case .singleWinner(let winner):
                self = .singleWinner(winner.value2.winner)
            case .tie(let winners):
                self = .tie(winners: winners.value2.winners)
            case .noVotes(_):
                self = .noVotes
        }
    }

}
