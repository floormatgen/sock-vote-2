extension Components.Schemas.PluralityVote {

  public var type: String {
    value1._type.rawValue
  }

  public var selection: String {
    value2.selection
  }

  public init(type: Components.Schemas.VotingStyle = .plurality, selection: String) {
    self.value1 = .init(
      _type: type
    )
    self.value2 = .init(
      selection: selection
    )
  }

}

extension Components.Schemas.PreferentialVote {

  public var type: String {
    value1._type.rawValue
  }

  public var selectionOrder: [String] {
    value2.selectionOrder
  }

  public init(type: Components.Schemas.VotingStyle = .preferential, selectionOrder: [String]) {
    self.value1 = .init(
      _type: type
    )
    self.value2 = .init(
      selectionOrder: selectionOrder
    )
  }

}

extension Components.Schemas.AnyVote {

  public var type: String {
    switch self {
    case .PluralityVote(let v): v.type
    case .PreferentialVote(let v): v.type
    }
  }

}
