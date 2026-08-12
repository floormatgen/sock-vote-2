import Foundation
import OpenAPIRuntime
import VoteHandling

public typealias DefaultRoomHandler = RoomHandler<DefaultRoomManager>

public struct RoomHandler<RoomManager: RoomManagerProtocol>: APIProtocol {

  let roomManager: RoomManager

  public init(roomManager: RoomManager) {
    self.roomManager = roomManager
  }

}

extension RoomHandler {

  // MARK: - Room Management

  public func postRoomCreate(
    _ input: Operations.PostRoomCreate.Input
  ) async throws -> Operations.PostRoomCreate.Output {
    switch input.body {
    case .json(let roomCreationRequest):
      do {
        let name = roomCreationRequest.name
        let fields = roomCreationRequest.fields
        let (code, adminToken) = try await roomManager.createRoom(name: name, fields: fields ?? [])
        return .ok(
          .init(body: .json(.init(name: name, fields: fields, code: code, adminToken: adminToken))))
      } catch let error as RoomError where .failedToGenerateCode == error {
        return .internalServerError(.init(body: .json(.init(reason: error.localizedDescription))))
      }
    }
  }

  // MARK: - Room Info

  public func getRoomCodeInfo(
    _ input: Operations.GetRoomCodeInfo.Input
  ) async throws -> Operations.GetRoomCodeInfo.Output {
    let code = input.path.code
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    return .ok(.init(body: .json(.init(name: room.name, code: room.code, fields: room.fields))))
  }

  // MARK: - Join Requests

  public func postRoomCodeJoin(
    _ input: Operations.PostRoomCodeJoin.Input
  ) async throws -> Operations.PostRoomCodeJoin.Output {
    let code = input.path.code
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    switch input.body {
    case .json(let joinRequest):
      let name = joinRequest.name
      let fields = joinRequest.fields?.additionalProperties
      // NOTE: This can suspend for a very long time
      let result = try await room.requestJoinRoom(name: name, fields: fields ?? [:])
      switch result {
      case .success(let participantToken):
        return .ok(.init(body: .json(.init(participantToken: participantToken))))
      case .rejected, .timeout:
        return .forbidden
      case .roomClosing:
        return .notFound
      }
    }
  }

  public func getRoomCodeJoinRequests(
    _ input: Operations.GetRoomCodeJoinRequests.Input
  ) async throws -> Operations.GetRoomCodeJoinRequests.Output {
    let code = input.path.code
    let adminToken = input.headers.roomAdminToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    guard room.verifyAdminToken(adminToken) else {
      return .forbidden(
        .init(
          body: .json(
            .roomAdminTokenInvalid(
              roomCode: code, adminToken: adminToken
            ))))
    }
    return .ok(
      .init(
        body: .json(
          .init(
            lastUpdated: Date.now.ISO8601Format(),
            requests: await room.joinRequests.map { token, request in
              let outFields =
                request.fields.isEmpty
                ? nil
                : Components.Schemas.Fields(additionalProperties: request.fields)
              return .init(
                name: request.name,
                participantToken: token,
                timestamp: request.timestamp.ISO8601Format(),
                fields: outFields
              )
            }
          ))))
  }

  public func postRoomCodeJoinRequests(
    _ input: Operations.PostRoomCodeJoinRequests.Input
  ) async throws -> Operations.PostRoomCodeJoinRequests.Output {
    let code = input.path.code
    let adminToken = input.headers.roomAdminToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    guard room.verifyAdminToken(adminToken) else {
      return .forbidden(
        .init(
          body: .json(
            .roomAdminTokenInvalid(
              roomCode: code, adminToken: adminToken
            ))))
    }
    var accepted = [String]()
    var rejected = [String]()
    var failed = [String]()
    switch input.body {
    case .json(let payload):
      if let toAccept = payload.accept {
        for token in toAccept {
          let result = await room.handleJoinRequest(true, forToken: token)
          if case .success = result {
            accepted.append(token)
          } else {
            failed.append(token)
          }
        }
      }
      if let toReject = payload.reject {
        for token in toReject {
          let result = await room.handleJoinRequest(false, forToken: token)
          if case .success = result {
            rejected.append(token)
          } else {
            failed.append(token)
          }
        }
      }
    }
    let result = Components.Schemas.JoinRequestsResult(
      accepted: accepted.isEmpty ? nil : accepted,
      rejected: rejected.isEmpty ? nil : rejected,
      failed: failed.isEmpty ? nil : failed
    )
    if !accepted.isEmpty || !rejected.isEmpty {
      return .ok(.init(body: .json(result)))
    } else {
      return .badRequest(.init(body: .json(result)))
    }
  }

  // MARK: - Question Handling

  public func getRoomCodeQuestion(
    _ input: Operations.GetRoomCodeQuestion.Input
  ) async throws -> Operations.GetRoomCodeQuestion.Output {
    // TODO: Could provide more information to a client, such as a number of votes in the future
    // if an admin token is provided.
    let code = input.path.code
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    guard let questionDescription = await room.currentQuestionDescription else {
      return .badRequest
    }
    return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
  }

  public func postRoomCodeQuestion(
    _ input: Operations.PostRoomCodeQuestion.Input
  ) async throws -> Operations.PostRoomCodeQuestion.Output {
    let code = input.path.code
    let adminToken = input.headers.roomAdminToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    guard room.verifyAdminToken(adminToken) else {
      return .forbidden(
        .init(
          body: .json(
            .roomAdminTokenInvalid(
              roomCode: code, adminToken: adminToken
            ))))
    }
    switch input.body {
    case .json(let question):
      try await room.updateQuestion(
        prompt: question.prompt,
        options: question.options,
        style: .init(question.votingStyle)
      )
      // We want to round trip the question to make sure it was created correctly
      guard let questionDescription = await room.currentQuestionDescription else {
        let reason = "Could not add the question to the room."
        return .internalServerError(.init(body: .json(.init(reason: reason))))
      }
      return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
    }
  }

  public func deleteRoomCodeQuestionID(
    _ input: Operations.DeleteRoomCodeQuestionID.Input
  ) async throws -> Operations.DeleteRoomCodeQuestionID.Output {
    let code = input.path.code
    let questionID = input.path.questionID
    let adminToken = input.headers.roomAdminToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    guard room.verifyAdminToken(adminToken) else {
      return .forbidden(
        .init(
          body: .json(
            .roomAdminTokenInvalid(
              roomCode: code, adminToken: adminToken
            ))))
    }
    guard let questionDescription = await room.currentQuestionDescription else {
      return .badRequest
    }
    guard questionDescription.id.uuidString == questionID else {
      return .badRequest
    }
    try await room.removeQuestion()
    return .ok(.init(body: .json(questionDescription.openAPIQuestion)))
  }

  public func putRoomCodeQuestionID(
    _ input: Operations.PutRoomCodeQuestionID.Input
  ) async throws -> Operations.PutRoomCodeQuestionID.Output {
    let code = input.path.code
    let questionID = input.path.questionID
    let adminToken = input.headers.roomAdminToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound
    }
    guard room.verifyAdminToken(adminToken) else {
      return .forbidden(
        .init(
          body: .json(
            .roomAdminTokenInvalid(
              roomCode: code, adminToken: adminToken
            ))))
    }
    guard
      let questionUUID = UUID(uuidString: questionID),
      await room.hasQuestion(with: questionUUID)
    else {
      return .badRequest
    }
    let newState: Question.State
    switch input.body {
    case .json(let body):
      switch body {
      case .open:
        newState = .open
      case .close:
        newState = .closed
      case .finalize:
        newState = .finalized
      }
    }
    do {
      try await room.setCurrentQuestionState(to: newState)
    } catch Room.Error.missingActiveQuestion {
      return .notFound
    } catch Question.Error.illegalStateChange(_, _) {
      return .badRequest
    }
    return .ok
  }

}

extension RoomHandler {

  public func getRoomCodeQuestionIDResult(
    _ input: Operations.GetRoomCodeQuestionIDResult.Input
  ) async throws -> Operations.GetRoomCodeQuestionIDResult.Output {
    let code = input.path.code
    let questionID = input.path.questionID
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound(.init(body: .json(.RoomError(.roomNotFound(roomCode: code)))))
    }
    guard let questionUUID = UUID(uuidString: questionID) else {
      return .notFound(
        .init(
          body: .json(
            .QuestionError(
              .questionNotFound(
                roomCode: code,
                questionID: questionID
              )))))
    }
    return try await room._getRoomCodeQuestionIDResult_handler(questionID: questionUUID)
  }

  public func getRoomCodeQuestionIDVotesInfo(
    _ input: Operations.GetRoomCodeQuestionIDVotesInfo.Input
  ) async throws -> Operations.GetRoomCodeQuestionIDVotesInfo.Output {
    let code = input.path.code
    let questionID = input.path.questionID
    let adminToken = input.headers.roomAdminToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound(
        .init(
          body: .json(
            .RoomError(
              .roomNotFound(
                roomCode: code
              )))))
    }
    return try await room._getRoomCodeQuestionIDVotesInfo_handler(
      questionID: questionID,
      adminToken: adminToken
    )
  }

}

extension RoomProtocol {

  // TODO: Handle when the room can store multiple questions

  fileprivate func _getRoomCodeQuestionIDResult_handler(
    questionID: UUID
  ) throws -> Operations.GetRoomCodeQuestionIDResult.Output {
    guard hasQuestion(with: questionID) else {
      return .notFound(
        .init(
          body: .json(
            .QuestionError(
              .questionNotFound(
                roomCode: code, questionID: questionID.uuidString
              )))))
    }
    guard let state = currentQuestionState else {
      preconditionFailure("\(#function): Question exists but no state reported")
    }
    guard state == .finalized else {
      return .badRequest(
        .init(
          body: .json(
            .questionNotFinalized(
              roomCode: code,
              questionID: questionID.uuidString,
              currentState: state.openAPIQuestionState
            ))))
    }
    guard
      let description = currentQuestionDescription,
      let result = try? currentQuestionResult,
      let voteCount = currentQuestionVoteCount
    else {
      preconditionFailure(
        """
        \(#function): Question should be finalized, but is missing \
        description, result or voteCount
        """
      )
    }
    return .ok(
      .init(
        body: .json(
          .init(
            description: description,
            voteCount: voteCount,
            result: result
          ))))
  }

  fileprivate func _getRoomCodeQuestionIDVotesInfo_handler(
    questionID: String,
    adminToken: String
  ) throws -> Operations.GetRoomCodeQuestionIDVotesInfo.Output {
    return .ok(
      .init(
        body: .json(
          .init(
            timestamp: Date.now.ISO8601Format(),
            voteCount: currentQuestionVoteCount ?? 0
          ))))
  }

}

// MARK: - Voting

extension RoomHandler {

  public func postRoomCodeQuestionIDVote(
    _ input: Operations.PostRoomCodeQuestionIDVote.Input
  ) async throws -> Operations.PostRoomCodeQuestionIDVote.Output {
    let code = input.path.code
    let questionID = input.path.questionID
    let participantToken = input.headers.participantToken
    guard let room = await roomManager.room(withCode: code) else {
      return .notFound(.init(body: .json(.RoomError(.roomNotFound(roomCode: code)))))
    }
    switch input.body {
    case .json(let anyVote):
      return try await room._postRoomCodeQuestionIDVote_handler(
        questionID: questionID,
        participantToken: participantToken,
        vote: anyVote
      )
    }
  }

}

extension RoomProtocol {

  /// Registers the vote for a specific participant
  ///
  /// This always runs on the Actor's executor, so reentrancy should not be an issue.
  fileprivate func _postRoomCodeQuestionIDVote_handler(
    questionID: String,
    participantToken: String,
    vote: Components.Schemas.AnyVote
  ) throws -> Operations.PostRoomCodeQuestionIDVote.Output {
    guard hasParticipant(withParticipantToken: participantToken) else {
      return .forbidden(
        .init(
          body: .json(
            .roomParticipantTokenInvalid(
              roomCode: code,
              participantToken: participantToken
            ))))
    }
    do {
      try registerVote(vote, forParticipant: participantToken)
      return .ok
    } catch let questionError as Question.Error {
      switch questionError {
      case .invalidVote, .voteStyleMismatch:
        return .badRequest
      default:
        throw questionError
      }
    }
  }

}
