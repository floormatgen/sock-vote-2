public import VoteHandling
import _PlatformFoundation

extension Question.Description {

  public var openAPIQuestion: Components.Schemas.Question {
    .init(
      value1: .init(
        prompt: prompt,
        votingStyle: votingStyle.openAPIVotingStyle,
        options: options
      ),
      value2: .init(
        id: id.uuidString,
        state: state.openAPIQuestionState
      )
    )
  }

}
