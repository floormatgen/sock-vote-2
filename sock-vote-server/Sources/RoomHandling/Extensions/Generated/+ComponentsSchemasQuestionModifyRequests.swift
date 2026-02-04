import VoteHandling

public extension Components.Schemas.QuestionOpenRequest {

    init() {
        self.init(_type: "open")
    }

}

public extension Components.Schemas.QuestionCloseRequest {

    init() {
        self.init(_type: "close")
    }

}

public extension Components.Schemas.QuestionFinalizeRequest {

    init() {
        self.init(_type: "close")
    }

}

public extension Components.Schemas.QuestionModifyRequest {

    init(from desiredState: Question.State) {
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
