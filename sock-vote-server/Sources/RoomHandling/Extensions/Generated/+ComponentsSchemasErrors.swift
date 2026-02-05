public extension Components.Schemas.RoomError {

    fileprivate init(
        _type type: Components.Schemas.ErrorType,
        description: String,
        roomCode: String,
    ) {
        self.init(
            value1: .init(
                _type: type, 
                description: description
            ), 
            value2: .init(
                roomCode: roomCode
            )
        )
    }

    static func roomNotFound(roomCode: String) -> Self {
        .init(
            _type: .roomNotFound, 
            description: "A room with the code \(roomCode) could not be found", 
            roomCode: roomCode
        )
    }

}


public extension Components.Schemas.QuestionError {

    fileprivate init(
        _type type: Components.Schemas.ErrorType,
        description: String,
        roomCode: String,
        questionID: String
    ) {
        self.init(
            value1: .init(
                _type: type, 
                description: description, 
                roomCode: roomCode
            ),
            value2: .init(
                questionID: questionID
            )
        )
    }

    static func questionNotFound(roomCode: String, questionID: String) -> Self {
        .init(
            _type: .questionNotFound,
            description: "Room \(roomCode) does not include a question with id \(questionID)",
            roomCode: roomCode,
            questionID: questionID
        )
    }
    
}

public extension Components.Schemas.QuestionStateError {

    fileprivate init(
        _type type: Components.Schemas.ErrorType,
        description: String,
        roomCode: String,
        questionID: String,
        currentState: Components.Schemas.QuestionState,
        allowedStates: [Components.Schemas.QuestionState]
    ) {
        self.init(
            value1: .init(
                _type: type, 
                description: description, 
                roomCode: roomCode, 
                questionID: questionID
            ), 
            value2: .init(
                currentState: currentState, 
                allowedStates: allowedStates
            )
        )
    }

    static func questionNotFinalized(
        roomCode: String,
        questionID: String,
        currentState: Components.Schemas.QuestionState
    ) -> Self {
        assert(currentState != .finalized)
        return self.init(
            _type: .questionNotFinalized, 
            description: "The question must be finalized to perform this action.", 
            roomCode: roomCode, 
            questionID: questionID, 
            currentState: currentState, 
            allowedStates: [.finalized]
        )
    }

}

// MARK: - Convenience Accessors

public extension Components.Schemas.RoomError {

    var _type: Components.Schemas.ErrorType {
        value1._type
    }

    var description: String {
        value1.description
    }

    var roomCode: String {
        value2.roomCode
    }

}

public extension Components.Schemas.QuestionError {

    var _type: Components.Schemas.ErrorType {
        value1._type
    }

    var description: String {
        value1.description
    }

    var roomCode: String {
        value1.roomCode
    }

    var questionID: String {
        value2.questionID
    }

}

public extension Components.Schemas.QuestionStateError {

    var _type: Components.Schemas.ErrorType {
        value1._type
    }

    var description: String {
        value1.description
    }

    var roomCode: String {
        value1.roomCode
    }

    var questionID: String {
        value1.questionID
    }

    var currentState: Components.Schemas.QuestionState {
        value2.currentState
    }

    var allowedStates: [Components.Schemas.QuestionState] {
        value2.allowedStates
    }

}
