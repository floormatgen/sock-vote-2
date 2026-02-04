import Testing
@testable import VoteHandling

extension QuestionTests {

    @Suite
    struct StateTests {

        @Test("Starts in opened state", arguments: Question.VotingStyle.allCases)
        func test_startsInOpenedState(_ style: Question.VotingStyle) throws {
            let question = try createQuestion(style: style)
            #expect(question.state == .opened)
        }

        @Test(
            "Can switch between opened and closed", 
            arguments: Question.VotingStyle.allCases,
            [
                (.opened, .opened),
                (.opened, .closed),
                (.closed, .opened),
                (.closed, .closed),
            ] as [(Question.State, Question.State)]
        )
        func test_canSwitchBetweenOpenedAndClosed(
            _ style: Question.VotingStyle, 
            _ states: (Question.State, Question.State)
        ) throws {
            let question = try createQuestion(style: style)
            try question.setState(states.0)
            #expect(question.state == states.0)
            try question.setState(states.1)
            #expect(question.state == states.1)
        }

        @Test(
            "Can change from any state to finalized",
            arguments: Question.VotingStyle.allCases,
            [.opened, .closed] as [Question.State]
        )
        func test_canChangeFromAnyStateToFinalized(
            _ style: Question.VotingStyle,
            _ state: Question.State
        ) throws {
            let question = try createQuestion(style: style)
            try question.setState(state)
            #expect(question.state == state)
            try question.setState(.finalized)
            #expect(question.state == .finalized)
        }

        @Test(
            "Cannot change from finalized",
            arguments: Question.VotingStyle.allCases,
            [.opened, .closed] as [Question.State]
        )
        func test_cannotChangeFromFinalized(
            _ style: Question.VotingStyle, 
            _ state: Question.State
        ) throws {
            let question = try createQuestion(style: style)
            try question.setState(.finalized)
            let error = try #require(throws: Question.Error.self) {
                try question.setState(state)
            }
            #expect(question.state == .finalized)
            guard case let .illegalStateChange(current, new) = error else {
                Issue.record("Unexpected Question error: \(error)")
                return
            }
            #expect(current == .finalized)
            #expect(new == state)
        }

    }
    
}
