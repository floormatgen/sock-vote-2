import VoteHandling
import Foundation

public extension Components.Schemas.QuestionFinalInfo {

    init(
        prompt: String,
        options: [String],
        questionID: String,
        state: Question.State,
        voteCount: Int,
        result: Question.Result
    ) {
        self.init(
            value1: .init(
                value1: .init(
                    prompt: prompt, 
                    options: options
                ), 
                value2: .init(
                    id: questionID,
                    state: state.openAPIQuestionState
                )
            ), 
            value2: .init(
                voteCount: voteCount, 
                result: result.openAPIQuestionResult
            )
        )
    }

    init(
        description: Question.Description,
        voteCount: Int,
        result: Question.Result
    ) {
        self.init(
            prompt: description.prompt, 
            options: description.options, 
            questionID: description.id.uuidString, 
            state: description.state, 
            voteCount: voteCount, 
            result: result
        )
    }

    var prompt: String {
        value1.prompt
    }

    var options: [String] {
        value1.options
    }

    var id: String {
        value1.id
    }

    var state: Components.Schemas.QuestionState {
        value1.state
    }

    var voteCount: Int {
        value2.voteCount
    }

    var result: Components.Schemas.QuestionResult {
        value2.result
    }

}
