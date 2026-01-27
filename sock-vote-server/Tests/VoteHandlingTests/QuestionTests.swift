import Testing
@testable import VoteHandling

@Suite
struct QuestionTests {

    @Test("Question created correctly", arguments: [.preferential, .plurality] as [Question.VotingStyle])
    func test_questionCreatedCorrectly(_ style: Question.VotingStyle) {
        let prompt = "John Question"
        let options = ["Foo", "Bar", "Baz"]
        let question = Question(prompt: prompt, options: options, votingStyle: style)
        #expect(question.prompt == prompt)
        #expect(question.options == options)
        #expect(question.votingStyle == style)
    }

}