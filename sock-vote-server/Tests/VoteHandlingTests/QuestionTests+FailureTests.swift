import Testing
@testable import VoteHandling

import Foundation

extension QuestionTests {

    @Suite
    struct FailureTests {

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

        @Test("Voting nonexistent option throws")
        func test_votingNonexistentOptionThrows() throws {
            let question = try createQuestion(options: ["foo", "bar"], style: .plurality)
            let error = try #require(throws: Question.Error.self) {
                let vote = Question.PluralityVote(selection: "bad")
                let token = UUID().uuidString
                try question.registerPluralityVote(vote, participantToken: token)
            }
            #expect(error == .invalidVote)
        }

        @Test("Specifying too few options throws")
        func test_specifyingTooFewOptionsThrows() throws {
            let question = try createQuestion(style: .preferential)
            let error = try #require(throws: Question.Error.self) {
                let vote = Question.PreferentialVote(selectionOrder: Array(question.options.dropFirst()))
                let token = UUID().uuidString
                try question.registerPreferentialVote(vote, participantToken: token)
            }
            #expect(error == .invalidVote)
        }

        @Test("Specifying too many options throws")
        func test_specifyingTooManyOptionsThrows() throws {
            let question = try createQuestion(style: .preferential)
            let error = try #require(throws: Question.Error.self) {
                let vote = Question.PreferentialVote(selectionOrder: question.options + ["bad"])
                let token = UUID().uuidString
                try question.registerPreferentialVote(vote, participantToken: token)
            }
            #expect(error == .invalidVote)
        }

        @Test("Specifying duplicate options throws")
        func test_specifyingDuplicateOptionsThrows() throws {
            let question = try createQuestion(style: .preferential)
            let error = try #require(throws: Question.Error.self) {
                var selection = question.options
                selection[0] = selection[1]
                let vote = Question.PreferentialVote(selectionOrder: selection)
                let token = UUID().uuidString
                try question.registerPreferentialVote(vote, participantToken: token)
            }
            #expect(error == .invalidVote)
        }

    }

}
