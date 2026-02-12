import Testing
@testable import RoomHandling

import VoteHandling
import Foundation

extension RoomHandlerTests {

    @Suite
    final class QuestionTests {
        let roomHandler: DefaultRoomHandler
        let code: String
        let adminToken: String
        let managerTask: Task<Void, any Error>

        init() async throws {
            let roomManager = DefaultRoomManager()
            self.roomHandler = DefaultRoomHandler(roomManager: roomManager)
            self.managerTask = Task { try await roomManager.run() }
            try await Task.sleep(for: .milliseconds(1))
            let (code, adminToken) = try await createRoom(on: roomHandler)
            self.code = code
            self.adminToken = adminToken
        }
        
        deinit {
            managerTask.cancel()
        }

        @Test("Admin can create question")
        func test_adminCanCreateQuestion() async throws {
            let prompt = "Question Prompt"
            let options = (0..<3).map { String($0) }

            let questionResponse = try await Self.createQuestionWithResponse(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken,
                prompt: prompt,
                options: options
            )

            let body = try questionResponse.ok.body.json
            #expect(body.prompt == prompt)
            #expect(body.options == options)
        }

        @Test("Cannot create question with invalid admin token")
        func test_cannotUpdateQuestionWithInvalidAdminToken() async throws {
            let badAdminToken = UUID().uuidString
            let response = try await Self.createQuestionWithResponse(
                on: roomHandler, 
                roomCode: code, 
                adminToken: badAdminToken
            )
            _ = try response.forbidden
        }

        @Test("Cannot create question for nonexistent room")
        func test_cannotCreateQuestionForNonexistentRoom() async throws {
            let response = try await Self.createQuestionWithResponse(
                on: roomHandler, 
                roomCode: "417167", // No room exists
                adminToken: UUID().uuidString
            )
            _ = try response.notFound
        }

        @Test("Admin can delete question")
        func test_adminCanDeleteQuestion() async throws {
            let id = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            try await Self.deleteQuestion(
                on: roomHandler, 
                roomCode: code, 
                questionID: id, 
                adminToken: adminToken
            )
            #expect(try await !Self.checkQuestionExists(on: roomHandler, roomCode: code))
        }

        @Test("Admin cannot delete question from missing room")
        func test_adminCannotDeleteQuestionFromMissingRoom() async throws {
            let id = try await Self.createQuestion(on: roomHandler, roomCode: code, adminToken: adminToken)
            let response = try await Self.deleteQuestionWithResponse(
                on: roomHandler, 
                roomCode: "bad", 
                questionID: id,
                adminToken: adminToken
            )
            #expect(throws: Never.self) { _ = try response.notFound }
            #expect(try await Self.checkQuestionExists(on: roomHandler, roomCode: code, id: id))
        }

        @Test("Cannot delete question with invalid admin token")
        func test_cannotDeleteQuestionWithInvalidAdminToken() async throws {
            let (code, adminToken) = try await createRoom(on: roomHandler)
            let id = try await Self.createQuestion(on: roomHandler, roomCode: code, adminToken: adminToken)
            let response = try await Self.deleteQuestionWithResponse(
                on: roomHandler, 
                roomCode: code,
                questionID: id,
                adminToken: adminToken + "67"
            )
            #expect(throws: Never.self) { _ = try response.forbidden }
            #expect(try await Self.checkQuestionExists(on: roomHandler, roomCode: code, id: id))
        }

        @Test("Cannot delete nonexistent question")
        func test_cannotDeleteNonexistentQuestion() async throws {
            let response = try await Self.deleteQuestionWithResponse(
                on: roomHandler, 
                roomCode: code,
                questionID: UUID().uuidString,
                adminToken: adminToken
            )
            #expect(throws: Never.self) { _ = try response.badRequest }
            #expect(try await !Self.checkQuestionExists(on: roomHandler, roomCode: code))
        }

        @Test("Question starts with open state")
        func test_questionStartsWithOpenState() async throws {
            let questionID = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            let state = try await Self.getQuestionState(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID
            )
            #expect(state == .open)
        }

        @Test(
            "Can switch state between open and closed",
            arguments: [
                (.open, .closed),
                (.closed, .open),
            ] as [(Question.State, Question.State)]
        )
        func test_canSwitchStateBetweenOpenAndClosed(
            _ first: Question.State, 
            _ second: Question.State
        ) async throws {
            let questionID = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            let firstState = try await Self.changeQuestionState(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID, 
                adminToken: adminToken, 
                state: first
            )
            #expect(firstState == first)
            let secondState = try await Self.changeQuestionState(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID, 
                adminToken: adminToken, 
                state: second
            )
            #expect(secondState == second)
        }

        @Test("Result is noVotes when question has no votes")
        func test_canGetQuestionResultWhenFinalized() async throws {
            let questionID = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            try await Self.changeQuestionState(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID,
                adminToken: adminToken, 
                state: .finalized
            )
            let result = try await Self.getQuestionResult(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID
            )
            #expect(result == .noVotes)
        }

        @Test(
            "Getting result not allowed when not finalized",
            arguments: [
                .open,
                .closed
            ] as [Question.State]
        )
        func test_gettingResultNotAllowedwhenNotFinalized(_ state: Question.State) async throws {
            let questionID = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            try await Self.changeQuestionState(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID, 
                adminToken: adminToken, 
                state: state
            )
            let response = try await Self.getQuestionResultWithResponse(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID
            )
            let body = try response.badRequest.body.json
            #expect(body._type == .questionNotFinalized)
            #expect(!body.description.isEmpty)
            #expect(body.roomCode == code)
            #expect(body.questionID == questionID)
            #expect(body.currentState == state.openAPIQuestionState)
            #expect(Set(body.allowedStates) == [.finalized])
        }

        @Test("Cannot get question result with invalid question id")
        func test_cannotGetQuestionResultWithInvalidQuestionID() async throws {
            let questionID = "bad"
            let response = try await Self.getQuestionResultWithResponse(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID
            )
            let body = try response.notFound.body.json
            guard case .QuestionError(let questionError) = body else {
                Issue.record("\(#function): Unexpected response body \(body)")
                return
            }
            #expect(questionError._type == .questionNotFound)
            #expect(!questionError.description.isEmpty)
            #expect(questionError.questionID == questionID)
        }

        @Test("Cannot get question result with invalid room code")
        func test_cannotGetQuestionResultWithInvalidRoomCode() async throws {
            let badRoomCode = "414141"
            let questionID = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            let response = try await Self.getQuestionResultWithResponse(
                on: roomHandler, 
                roomCode: badRoomCode, 
                questionID: questionID
            )
            let body = try response.notFound.body.json
            guard case .RoomError(let roomError) = body else {
                Issue.record("\(#function): Unexpected response body \(body)")
                return
            }
            #expect(roomError._type == .roomNotFound)
            #expect(!roomError.description.isEmpty)
        }

        @Test("Can get question votes info", arguments: [0, 1, 10, 100])
        func test_canGetQuestionVotesInfo(_ expectedVoteCount: Int) async throws {
            let timeLeniance = 1.0
            let startDate = Date.now - timeLeniance
            let questionID = try await Self.createQuestion(
                on: roomHandler, 
                roomCode: code, 
                adminToken: adminToken
            )
            for i in 0..<expectedVoteCount {
                let name = "Participant \(i)"
                let participantToken = try await forceJoinRoom(
                    on: roomHandler, 
                    roomCode: code, 
                    adminToken: adminToken, 
                    name: name
                )
                try await Self.voteOnQuestion(
                    on: roomHandler, 
                    roomCode: code, 
                    questionID: questionID, 
                    participantToken: participantToken, 
                    vote: .plurality(Self.defaultQuestionOptions[(1..<3).randomElement()!])
                )
            }
            let (timestampString, voteCount) = try await Self.getVotesInfo(
                on: roomHandler, 
                roomCode: code, 
                questionID: questionID, 
                adminToken: adminToken
            )
            let timestamp = try Utilities.parseTimestamp(timestampString)
            #expect((startDate...(Date.now + timeLeniance)).contains(timestamp))
            #expect(expectedVoteCount == voteCount)
        }

        // MARK: - Utilities

        static var defaultQuestionName: String {
            "Question"
        }

        static var defaultQuestionOptions: [String] {
            ["Option 1", "Option 2", "Option 3"]
        }

        static func createQuestionWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            adminToken: String,
            prompt: String = defaultQuestionName,
            options: [String] = defaultQuestionOptions,
            votingStyle: Question.VotingStyle = .plurality
        ) async throws -> Operations.PostRoomCodeQuestion.Output {
            try await roomHandler.postRoomCodeQuestion(.init(
                path: .init(
                    code: roomCode
                ),
                headers: .init(
                    roomAdminToken: adminToken
                ),
                body: .json(.init(
                    prompt: prompt, 
                    votingStyle: votingStyle.openAPIVotingStyle, 
                    options: options
                ))
            ))
        }

        @discardableResult
        static func createQuestion(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            adminToken: String,
            prompt: String = defaultQuestionName,
            options: [String] = defaultQuestionOptions,
            votingStyle: Question.VotingStyle = .plurality
        ) async throws -> String {
            let response = try await createQuestionWithResponse(
                on: roomHandler, 
                roomCode: roomCode, 
                adminToken: adminToken, 
                prompt: prompt, 
                options: options, 
                votingStyle: votingStyle
            )
            let body = try response.ok.body.json
            #expect(body.prompt == prompt)
            #expect(body.options == options)
            #expect(body.votingStyle == votingStyle.openAPIVotingStyle)
            #expect(try await Self.checkQuestionExists(on: roomHandler, roomCode: roomCode))
            return body.id
        }

        static func checkQuestionExists(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            id: String? = nil
        ) async throws -> Bool {
            let response = try await roomHandler.getRoomCodeQuestion(
                .init(
                    path: .init(
                        code: roomCode
                    )
                )
            )
            switch response {
                case .ok(let output):
                    if let id = id {
                        #expect(try output.body.json.id == id)
                    }
                    return true
                default:
                    return false
            }
        }

        static func deleteQuestionWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            adminToken: String
        ) async throws -> Operations.DeleteRoomCodeQuestionID.Output {
            try await roomHandler.deleteRoomCodeQuestionID(
                .init(
                    path: .init(
                        code: roomCode,
                        questionID: questionID
                    ), 
                    headers: .init(
                        roomAdminToken: adminToken
                    )
                )
            )
        }

        @discardableResult
        static func deleteQuestion(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            adminToken: String
        ) async throws -> Bool {
            let response = try await Self.deleteQuestionWithResponse(
                on: roomHandler, 
                roomCode: roomCode,
                questionID: questionID,
                adminToken: adminToken
            )
            return switch response {
                case .ok: true
                default: false
            }
        }

        static func changeQuestionStateWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            adminToken: String,
            state: Question.State
        ) async throws -> Operations.PutRoomCodeQuestionID.Output {
            try await roomHandler.putRoomCodeQuestionID(
                .init(
                    path: .init(
                        code: roomCode,
                        questionID: questionID
                    ), 
                    headers: .init(
                        roomAdminToken: adminToken
                    ),
                    body: .json(.init(
                        from: state
                    ))
                )
            )
        }

        @discardableResult
        static func changeQuestionState(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            adminToken: String,
            state: Question.State
        ) async throws -> Question.State {
            let response = try await Self.changeQuestionStateWithResponse(
                on: roomHandler, 
                roomCode: roomCode, 
                questionID: questionID, 
                adminToken: adminToken, 
                state: state
            )
            _ = try response.ok
            let newState = try await Self.getQuestionState(
                on: roomHandler,
                roomCode: roomCode,
                questionID: questionID
            )
            #expect(newState == state)
            return state
        }

        static func getQuestionDescriptionWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String
        ) async throws -> Operations.GetRoomCodeQuestion.Output {
            try await roomHandler.getRoomCodeQuestion(
                .init(
                    path: .init(
                        code: roomCode
                    )
                )
            )
        }

        static func getQuestionState(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String
        ) async throws -> Question.State {
            let response = try await Self.getQuestionDescriptionWithResponse(
                on: roomHandler,
                roomCode: roomCode, 
                questionID: questionID
            )
            let state = try response.ok.body.json.state
            return .init(state)
        }

        static func getQuestionResultWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String
        ) async throws -> Operations.GetRoomCodeQuestionIDResult.Output {
            try await roomHandler.getRoomCodeQuestionIDResult(
                .init(
                    path: .init(
                        code: roomCode,
                        questionID: questionID
                    )
                )
            )
        }

        static func getQuestionResult(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String
        ) async throws -> Question.Result {
            let response = try await Self.getQuestionResultWithResponse(
                on: roomHandler, 
                roomCode: roomCode, 
                questionID: questionID
            )
            let body = try response.ok.body.json
            #expect(body.id == questionID)
            return .init(body.result)
        }

        enum Vote {
            case plurality(String)
            case preferential([String])
        }

        static func voteOnQuestionWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            participantToken: String,
            vote: Vote
        ) async throws -> Operations.PostRoomCodeQuestionIDVote.Output {
            let anyVote: Components.Schemas.AnyVote
            switch vote {
                case .plurality(let s):
                    anyVote = .PluralityVote(.init(selection: s))
                case .preferential(let so):
                    anyVote = .PreferentialVote(.init(selectionOrder: so))
            }
            return try await roomHandler.postRoomCodeQuestionIDVote(
                .init(
                    path: .init(
                        code: roomCode, 
                        questionID: questionID
                    ), 
                    headers: .init(
                        participantToken: participantToken
                    ), 
                    body: .json(anyVote)
                )
            )
        }

        static func voteOnQuestion(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            participantToken: String,
            vote: Vote
        ) async throws {
            let response = try await Self.voteOnQuestionWithResponse(
                on: roomHandler, 
                roomCode: roomCode, 
                questionID: questionID, 
                participantToken: participantToken, 
                vote: vote
            )
            _ = try response.ok
        }

        static func getVotesInfoWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            adminToken: String
        ) async throws -> Operations.GetRoomCodeQuestionIDVotesInfo.Output {
            try await roomHandler.getRoomCodeQuestionIDVotesInfo(
                .init(
                    path: .init(
                        code: roomCode, 
                        questionID: questionID
                    ), 
                    headers: .init(
                        roomAdminToken: adminToken
                    )
                )
            )
        }

        static func getVotesInfo(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            adminToken: String            
        ) async throws -> (timestamp: String, voteCount: Int) {
            let response = try await Self.getVotesInfoWithResponse(
                on: roomHandler, 
                roomCode: roomCode, 
                questionID: questionID, 
                adminToken: adminToken
            )
            let body = try response.ok.body.json
            return (body.timestamp, body.voteCount)
        }

    }

}
