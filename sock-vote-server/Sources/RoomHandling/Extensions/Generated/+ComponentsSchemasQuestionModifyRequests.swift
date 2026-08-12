public import VoteHandling

extension Components.Schemas.QuestionOpenRequest {

  public init() {
    self.init(_type: "open")
  }

}

extension Components.Schemas.QuestionCloseRequest {

  public init() {
    self.init(_type: "close")
  }

}

extension Components.Schemas.QuestionFinalizeRequest {

  public init() {
    self.init(_type: "close")
  }

}

extension Components.Schemas.QuestionModifyRequest {

  public init(from desiredState: Question.State) {
    switch desiredState {
    case .open:
      self = .open(.init())
    case .closed:
      self = .close(.init())
    case .finalized:
      self = .finalize(.init())
    }
  }

}
