import Testing
@testable import VoteHandling

extension VoteCalculationTests {

    @Suite
    struct PreferentialTests {

        @Test("No result with no votes")
        func test_hasNoResultWithNoVotes() throws {
            let result = try Question.preferentialResult(using: EmptyCollection(), options: defaultOptions)
            #expect(result == .noVotes)
        }

        @Test("Can find concrete winner")
        func test_canFindConcreteWinner() throws {
            let optionsArray = Array(defaultOptions)
            let votes = [
                [optionsArray[0], optionsArray[1], optionsArray[2]],
                [optionsArray[0], optionsArray[2], optionsArray[1]],
                [optionsArray[1], optionsArray[0], optionsArray[2]],
            ]
            .map { Question.PreferentialVote(selectionOrder: $0) }
            let result = try Question.preferentialResult(using: votes, options: defaultOptions)
            guard case .hasWinner(let winner) = result else {
                Issue.record("\(#function): result (\(result)) not equal to .hasWinner(_:)")
                return
            }
            #expect(winner == optionsArray[0])
        }

    }

}
