import VoteHandling
import Foundation

internal extension RoomHandler {

    //! FIXME: Region-based isolation checker can't handle using an isolated parameter here,
    //! switch to using an isolated parameter when compiler supports it.

    // TODO: Make operation closures isolated to room

    /// Does common request checks for admin operations on questions
    func withVerifiedQuestionAndAdmin<E: Error, Output: Validation.RoomAdminQuestionOutput>(
        roomCode: String,
        questionID: String,
        adminToken: String,
        outputType: Output.Type = Output.self,
        operation: sending (_ room: /* isolated */ RoomManager.Room, _ adminToken: String, _ questionUUID: UUID) 
            async throws(E) -> sending Output
    ) async throws(E) -> sending Output {
        guard let room = await roomManager.room(withCode: roomCode) else {
            return .notFound(.init(body: .json(.RoomError(.roomNotFound(
                roomCode: roomCode
            )))))
        }
        return try await { (_ room: isolated RoomManager.Room) async throws(E) -> sending Output in
            guard room.verifyAdminToken(adminToken) else {
                return .forbidden(.init(body: .json(.roomAdminTokenInvalid(
                    roomCode: roomCode, 
                    adminToken: adminToken
                ))))
            }
            guard
                let questionUUID = UUID(uuidString: questionID),
                room.hasQuestion(with: questionUUID)
            else {
                return .notFound(.init(body: .json(.QuestionError(.questionNotFound(
                    roomCode: roomCode, 
                    questionID: questionID
                )))))
            }
            return try await operation(room, adminToken, questionUUID)
        }(room)
    }

    func withVerifiedQuestionAndAdmin<
        E: Error,
        Input: Validation.RoomAdminQuestionInput, Output: Validation.RoomAdminQuestionOutput
    >(
        input: Input,
        outputType: Output.Type = Output.self,
        operation: sending (_ room: /* isolated */ RoomManager.Room, _ adminToken: String, _ questionUUID: UUID)
            async throws(E) -> sending Output
    ) async throws(E) -> sending Output {
        let path = input.path
        let code = path.code
        let questionID = path.questionID
        let adminToken = input.headers.roomAdminToken
        return try await withVerifiedQuestionAndAdmin(
            roomCode: code,
            questionID: questionID,
            adminToken: adminToken,
            operation: operation
        )
    }

    func withVerifiedQuestion<E: Error, Output: Validation.RoomQuestionOutput>(
        roomCode: String,
        questionID: String,
        outputType: Output.Type = Output.self,
        operation: sending (_ room: /* isolated */ RoomManager.Room, _ questionUUID: UUID) 
            async throws(E) -> sending Output
    ) async throws(E) -> sending Output {
        guard let room = await roomManager.room(withCode: roomCode) else {
            return .notFound(.init(body: .json(.RoomError(.roomNotFound(
                roomCode: roomCode
            )))))
        }
        return try await { (_ room: isolated RoomManager.Room) async throws(E) -> sending Output in 
            guard
                let questionUUID = UUID(uuidString: questionID),
                room.hasQuestion(with: questionUUID)
            else {
                return .notFound(.init(body: .json(.QuestionError(.questionNotFound(
                    roomCode: roomCode, 
                    questionID: questionID
                )))))
            }
            return try await operation(room, questionUUID)
        }(room)
    }

    func withVerifiedQuestion<
        E: Error,
        Input: Validation.RoomQuestionInput, Output: Validation.RoomQuestionOutput
    >(
        input: Input,
        outputType: Output.Type = Output.self,
        operation: sending (_ room: /* isolated */ RoomManager.Room, _ questionUUID: UUID)
            async throws(E) -> sending Output
    ) async throws (E) -> sending Output {
        let path = input.path
        let code = path.code
        let questionID = path.questionID
        return try await withVerifiedQuestion(
            roomCode: code, 
            questionID: questionID, 
            operation: operation
        )
    }

}

internal enum Validation {

    protocol RoomInput {
        associatedtype Path: RoomPath
        var path: Path { get }
    }

    protocol RoomQuestionInput: RoomInput where Path: RoomQuestionPath {
        
    }

    protocol RoomAdminQuestionInput: RoomQuestionInput {
        associatedtype Headers: RoomAdminHeaders
        var headers: Headers { get }
    }

    protocol RoomPath {
        var code: String { get }
    }

    protocol RoomQuestionPath: RoomPath {
        var questionID: String { get }
    }

    protocol RoomAdminHeaders {
        var roomAdminToken: String { get }
    }

    protocol RoomQuestionOutput: Sendable {
        static func notFound(_: Components.Responses.RoomOrQuestionNotFound) -> Self
    }

    protocol RoomAdminQuestionOutput: RoomQuestionOutput {
        static func forbidden(_: Components.Responses.RoomAdminTokenInvalid) -> Self
    }

}

// MARK: - Conformances

extension Operations.GetRoomCodeQuestionIDVotesInfo.Input: Validation.RoomAdminQuestionInput {}
extension Operations.GetRoomCodeQuestionIDVotesInfo.Input.Path: Validation.RoomQuestionPath {}
extension Operations.GetRoomCodeQuestionIDVotesInfo.Input.Headers: Validation.RoomAdminHeaders {}
extension Operations.GetRoomCodeQuestionIDVotesInfo.Output: Validation.RoomAdminQuestionOutput {}

extension Operations.GetRoomCodeQuestionIDResult.Input: Validation.RoomQuestionInput {}
extension Operations.GetRoomCodeQuestionIDResult.Input.Path: Validation.RoomQuestionPath {}
extension Operations.GetRoomCodeQuestionIDResult.Output: Validation.RoomQuestionOutput {}
