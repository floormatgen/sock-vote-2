import Testing
@testable import VoteHandling

import Foundation

@Suite
struct QuestionTests {

    @Test("Question created correctly", arguments: Question.VotingStyle.allCases)
    func test_questionCreatedCorrectly(_ style: Question.VotingStyle) throws {
        let prompt = "John Question"
        let options = ["Foo", "Bar", "Baz"]
        _ = try Self.createQuestion(prompt: prompt, options: options, style: style)
    }
    
    @Test("Vote counted successfully", arguments: Question.VotingStyle.allCases)
    func test_voteCounted(_ style: Question.VotingStyle) throws {
        let question = try Self.createQuestion(prompt: "foo", options: ["bar", "baz"], style: style)
        let token = UUID().uuidString
        switch style {
            case .plurality:
                let vote = Question.PluralityVote(selection: question.options[0])
                try question.registerPluralityVote(vote, participantToken: token)
            case .preferential:
                let vote = Question.PreferentialVote(selectionOrder: question.options)
                try question.registerPreferentialVote(vote, participantToken: token)
        }
        #expect(question.voteCount == 1)
        #expect(question.hasVoted(participantToken: token))
    }
    
    @Test("Cannot vote more than once", arguments: Question.VotingStyle.allCases)
    func test_cannotVoteMoreThanOnce(_ style: Question.VotingStyle) throws {
        let question = try Self.createQuestion(prompt: "foo", options: ["bar", "baz"], style: style)
        let token = UUID().uuidString
        
        func vote(flip: Bool) throws {
            switch style {
                case .plurality:
                    let vote = Question.PluralityVote(selection: question.options[flip ? 1 : 0])
                    try question.registerPluralityVote(vote, participantToken: token)
                case .preferential:
                    let vote = Question.PreferentialVote(selectionOrder: flip ? Array(question.options.reversed()) : question.options)
                    try question.registerPreferentialVote(vote, participantToken: token)
            }
        }
        
        try vote(flip: false)
        #expect(question.hasVoted(participantToken: token))
        #expect(question.voteCount == 1)
        try vote(flip: true)
        #expect(question.hasVoted(participantToken: token))
        #expect(question.voteCount == 1)
    }

    @Test("Description matches question", arguments: Question.VotingStyle.allCases)
    func test_descriptionMatchesQuestion(_ style: Question.VotingStyle) throws {
        let prompt = "Question Name"
        let options = ["Option 1", "Option 2", "Option 3"]
        let question = try Self.createQuestion(prompt: prompt, options: options, style: style)
        let questionDescription = question.questionDescription
        #expect(questionDescription.prompt == prompt)
        #expect(questionDescription.id == question.id)
        #expect(questionDescription.votingStyle == style)
    }

    @Test("Question.VotingStyle LosslessStringConvertible round trip", arguments: Question.VotingStyle.allCases)
    func test_questionVotingStyleLosslessStringConvertibleRoundTrip(_ style: Question.VotingStyle) throws {
        // NOTE: Currently emits a warning due to a compiler bug
        #expect(try style == #require(.init(style.description)))
    }

    @Test("[plurality] Question.result is correct when queried")
    func test_resultIsCorrect_plurality() throws {
        let question = try Self.createQuestion(style: .plurality)

        let votes = [
            repeatElement("Option 1", count: 5),
            repeatElement("Option 2", count: 10),
            repeatElement("Option 3", count: 2),
        ]
        .flatMap(\.self)
        .map { Question.PluralityVote(selection: $0) }

        try votes.forEach { vote in 
            let token = UUID().uuidString
            try question.registerPluralityVote(vote, participantToken: token)
        }

        let result = try question.result
        #expect(result == .hasWinner("Option 2"))
    }

    @Test("[preferential] Question.result is correct when queried", arguments: [
        .init(
            "Basic winner",
            votes: [
                [0, 1, 2],
                [0, 1, 2],
                [2, 1, 0],
            ], expectedResult: 0),
        .init(
            "Basic tie",
            votes: [
                [0, 1, 2],
                [1, 2, 0],
                [2, 0, 1],
            ], expectedResult: [0, 1, 2]),
        .init(
            "No votes",
            votes: [],
            expectedResult: [])
    ] as [PreferentialArgument])
    func test_resultIsCorrect_preferential(_ testArgument: PreferentialArgument) throws {
        let question = try Self.createQuestion(options: testArgument.optionsArray, style: .preferential)
        
        try testArgument.votes.forEach { vote in
            let token = UUID().uuidString
            try question.registerPreferentialVote(vote, participantToken: token)
        }

        try testArgument.checkResult(try question.result)
    }
    
    // MARK: - Helpers

    typealias PreferentialArgument = VoteCalculationTests.PreferentialTests.TestArgument
    
    static func createQuestion(
        prompt: String = "Question Prompt", 
        options: [String] = ["Option 1", "Option 2", "Option 3"], 
        style: Question.VotingStyle
    ) throws -> Question {
        let question = try Question.create(prompt: prompt, options: options, votingStyle: style)
        #expect(question.prompt == prompt)
        #expect(question.options == options)
        #expect(question.votingStyle == style)
        return question
    }

}
