import VoteHandling

public extension Question.PluralityVote {

    init(_ pluralityVote: Components.Schemas.PluralityVote) {
        self.init(selection: pluralityVote.selection)
    }

}

public extension Question.PreferentialVote {

    init(_ preferentialVote: Components.Schemas.PreferentialVote) {
        self.init(selectionOrder: preferentialVote.selectionOrder)
    }
    
}
