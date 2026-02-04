public extension Components.Schemas.PluralityVote {

    var type: String {
        value1._type.rawValue
    }

    var selection: String {
        value2.selection
    }

    init(type: Components.Schemas.VotingStyle = .plurality, selection: String) {
        self.value1 = .init(
            _type: type
        )
        self.value2 = .init(
            selection: selection
        )
    }

}

public extension Components.Schemas.PreferentialVote {

    var type: String {
        value1._type.rawValue
    }

    var selectionOrder: [String] {
        value2.selectionOrder
    }

    init(type: Components.Schemas.VotingStyle = .preferential, selectionOrder: [String]) {
        self.value1 = .init(
            _type: type
        )
        self.value2 = .init(
            selectionOrder: selectionOrder
        )
    }

}

public extension Components.Schemas.AnyVote {

    var type: String {
        switch self {
            case .PluralityVote(let v): v.type
            case .PreferentialVote(let v): v.type
        }
    }

}
