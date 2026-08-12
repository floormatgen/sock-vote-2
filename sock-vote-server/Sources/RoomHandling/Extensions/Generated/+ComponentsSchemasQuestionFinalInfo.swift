public import VoteHandling
import _PlatformFoundation

extension Components.Schemas.QuestionFinalInfo {

  public init(
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

  public init(
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

  public var prompt: String {
    value1.prompt
  }

  public var options: [String] {
    value1.options
  }

  public var id: String {
    value1.id
  }

  public var state: Components.Schemas.QuestionState {
    assert(
      value1.state == .finalized,
      "\(#function): Question must be finalized to create RoomFinalInfo"
    )
    return value1.state
  }

  public var voteCount: Int {
    value2.voteCount
  }

  public var result: Components.Schemas.QuestionResult {
    value2.result
  }

}
