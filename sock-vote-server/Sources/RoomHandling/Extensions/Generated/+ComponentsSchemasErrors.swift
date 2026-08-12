extension Components.Schemas.RoomError {

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

  public static func roomNotFound(roomCode: String) -> Self {
    .init(
      _type: .roomNotFound,
      description: "A room with the code \(roomCode) could not be found",
      roomCode: roomCode
    )
  }

}

extension Components.Schemas.QuestionError {

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

  public static func questionNotFound(roomCode: String, questionID: String) -> Self {
    .init(
      _type: .questionNotFound,
      description: "Room \(roomCode) does not include a question with id \(questionID)",
      roomCode: roomCode,
      questionID: questionID
    )
  }

}

extension Components.Schemas.QuestionStateError {

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

  public static func questionNotFinalized(
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

extension Components.Schemas.RoomParticipantError {

  fileprivate init(
    _type type: Components.Schemas.ErrorType,
    description: String,
    roomCode: String,
    participantToken: String
  ) {
    self.init(
      value1: .init(
        _type: type,
        description: description,
        roomCode: roomCode
      ),
      value2: .init(
        participantToken: participantToken
      )
    )
  }

  public static func roomParticipantTokenInvalid(
    roomCode: String,
    participantToken: String
  ) -> Self {
    self.init(
      _type: .roomParticipantTokenInvalid,
      description: "The participant token \(participantToken) is invalid for room \(roomCode)",
      roomCode: roomCode,
      participantToken: participantToken
    )
  }

}

extension Components.Schemas.RoomAdminError {

  fileprivate init(
    _type type: Components.Schemas.ErrorType,
    description: String,
    roomCode: String,
    adminToken: String
  ) {
    self.init(
      value1: .init(
        _type: type,
        description: description,
        roomCode: roomCode
      ),
      value2: .init(
        adminToken: adminToken
      )
    )
  }

  public static func roomAdminTokenInvalid(
    roomCode: String,
    adminToken: String
  ) -> Self {
    self.init(
      _type: .roomAdminTokenInvalid,
      description: "The admin token \(adminToken) is invalid for room \(roomCode)",
      roomCode: roomCode,
      adminToken: adminToken
    )
  }

}

// MARK: - Convenience Accessors

extension Components.Schemas.RoomError {

  public var _type: Components.Schemas.ErrorType {
    value1._type
  }

  public var description: String {
    value1.description
  }

  public var roomCode: String {
    value2.roomCode
  }

}

extension Components.Schemas.QuestionError {

  public var _type: Components.Schemas.ErrorType {
    value1._type
  }

  public var description: String {
    value1.description
  }

  public var roomCode: String {
    value1.roomCode
  }

  public var questionID: String {
    value2.questionID
  }

}

extension Components.Schemas.QuestionStateError {

  public var _type: Components.Schemas.ErrorType {
    value1._type
  }

  public var description: String {
    value1.description
  }

  public var roomCode: String {
    value1.roomCode
  }

  public var questionID: String {
    value1.questionID
  }

  public var currentState: Components.Schemas.QuestionState {
    value2.currentState
  }

  public var allowedStates: [Components.Schemas.QuestionState] {
    value2.allowedStates
  }

}
