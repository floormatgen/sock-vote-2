extension Components.Schemas.Question {

  public var prompt: String {
    value1.prompt
  }

  public var votingStyle: Components.Schemas.VotingStyle? {
    value1.votingStyle
  }

  public var options: [String] {
    value1.options
  }

  public var id: String {
    value2.id
  }

  public var state: Components.Schemas.QuestionState {
    value2.state
  }

}
