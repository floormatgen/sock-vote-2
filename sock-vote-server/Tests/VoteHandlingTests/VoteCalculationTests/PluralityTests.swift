import Testing
@testable import VoteHandling

extension VoteCalculationTests {

    @Suite
    struct PluralityTests {

        @Test("No result with no votes")
        func test_noResultWithNoVotes() throws {
            let result = try Question.preferentialResult(using: EmptyCollection(), options: defaultOptions)
            #expect(result == .noVotes)
        }

        @Test("Can handle complete ties", arguments: 1...3)
        func test_handlesTiedResult(_ duplicatedVotes: Int) throws {
            let votes = repeatElement(defaultOptions, count: duplicatedVotes)
                .flatMap(\.self)
                .map { Question.PluralityVote(selection: $0) }
            let result = try Question.pluralityResult(using: votes, options: defaultOptions)
            guard case .tie(let winners) = result else {
                Issue.record("\(#function): result (\(result)) not equal to .tie(winners:)")
                return
            }
            #expect(Set(winners) == defaultOptions)
        }

        @Test("Can handle partial ties", arguments: 1...3, defaultOptions)
        func test_canHandlePartialTies(_ duplicatedVotes: Int, _ ignoring: String) throws {
            var voteOptions = defaultOptions
            voteOptions.remove(ignoring)
            let votes = repeatElement(voteOptions, count: duplicatedVotes)
                .flatMap(\.self)
                .map { Question.PluralityVote(selection: $0) }
            let result = try Question.pluralityResult(using: votes, options: defaultOptions)
            guard case .tie(let winners) = result else {
                Issue.record("\(#function): result (\(result)) not equal to .tie(winners:)")
                return
            }
            #expect(Set(winners) == voteOptions)
        }

        @Test("Can find concrete winner")
        func test_canFindConcreteWinner() throws {
            let optionsArray = Array(defaultOptions)
            let votes = [
                repeatElement(optionsArray[0], count: 100),
                repeatElement(optionsArray[1], count: 50),
                repeatElement(optionsArray[2], count: 99),
            ]
            .flatMap(\.self)
            .map { Question.PluralityVote(selection: $0) }
            let result = try Question.pluralityResult(using: votes, options: defaultOptions)
            guard case .hasWinner(let winner) = result else {
                Issue.record("\(#function): result (\(result)) not equal to .hasWinner(_:)")
                return
            }
            #expect(winner == optionsArray[0])
        }

    }

}
