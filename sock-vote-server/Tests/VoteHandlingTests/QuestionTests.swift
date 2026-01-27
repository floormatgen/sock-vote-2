import Testing
@testable import VoteHandling

import Foundation

@Suite
struct QuestionTests {

    @Test("Question created correctly", arguments: Question.VotingStyle.allCases)
    func test_questionCreatedCorrectly(_ style: Question.VotingStyle) throws {
        let prompt = "John Question"
        let options = ["Foo", "Bar", "Baz"]
        _ = try createQuestion(prompt: prompt, options: options, style: style)
    }
    
    @Test("Vote counted successfully", arguments: Question.VotingStyle.allCases)
    func test_voteCounted(_ style: Question.VotingStyle) throws {
        let question = try createQuestion(prompt: "foo", options: ["bar", "baz"], style: style)
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
        let question = try createQuestion(prompt: "foo", options: ["bar", "baz"], style: style)
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
        let question = try createQuestion(prompt: prompt, options: options, style: style)
        let questionDescription = question.questionDescription
        #expect(questionDescription.prompt == prompt)
        #expect(questionDescription.id == question.id)
        #expect(questionDescription.style == style)
    }

    @Test("Question.VotingStyle LosslessStringConvertible round trip", arguments: Question.VotingStyle.allCases)
    func test_QuestionVotingStyleLosslessStringConvertibleRoundTrip(_ style: Question.VotingStyle) throws {
        // NOTE: Currently emits a warning due to a bug
        #expect(try style == #require(.init(style.description)))
    }

    @Test("Attempting to add invalid vote throws", arguments: Question.VotingStyle.allCases) 
    func test_attemptingToAddInvalidVoteThrows(_ style: Question.VotingStyle) throws {
        let question = try createQuestion(style: style)
        let token = UUID().uuidString
        var actualStyle: Question.VotingStyle?
        let error = try #require(throws: Question.Error.self) {
            switch style {
                case .plurality:
                    actualStyle = .preferential
                    let vote = Question.PreferentialVote(selectionOrder: question.options)
                    try question.registerPreferentialVote(vote, participantToken: token)
                case .preferential:
                    actualStyle = .plurality
                    let vote = Question.PluralityVote(selection: question.options.first!)
                    try question.registerPluralityVote(vote, participantToken: token)
            }
        }
        #expect(error == .voteStyleMismatch(expected: style, received: try #require(actualStyle)))
    }

    @Test("Creating question with no options throws", arguments: Question.VotingStyle.allCases)
    func test_creatingQuestionWithNoOptionsThrows(_ style: Question.VotingStyle) throws {
        let error = try #require(throws: Question.Error.self) {
            try createQuestion(options: [], style: style)
        }
        #expect(error == .noOptions)
    }
    
    // MARK: - Helpers
    
    func createQuestion(
        prompt: String = "Question Prompt", 
        options: [String] = ["Option 1", "Option 2", "Option 3"], 
        style: Question.VotingStyle
    ) throws -> Question {
        let question = try Question(prompt: prompt, options: options, votingStyle: style)
        #expect(question.prompt == prompt)
        #expect(question.options == options)
        #expect(question.votingStyle == style)
        return question
    }

}
