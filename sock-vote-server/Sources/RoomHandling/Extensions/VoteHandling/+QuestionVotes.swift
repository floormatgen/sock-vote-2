public import VoteHandling

extension Question.PluralityVote {

  public init(_ pluralityVote: Components.Schemas.PluralityVote) {
    self.init(selection: pluralityVote.selection)
  }

}

extension Question.PreferentialVote {

  public init(_ preferentialVote: Components.Schemas.PreferentialVote) {
    self.init(selectionOrder: preferentialVote.selectionOrder)
  }

}
