import Testing
@testable import RoomHandling

extension RoomHandlerTests {

    @Suite
    struct VoteTests {
        let roomHandler: DefaultRoomHandler
        let roomCode: String
        let adminToken: String
        let questionID: String

        init() async throws {
            let roomManager = DefaultRoomManager()
            self.roomHandler = DefaultRoomHandler(roomManager: roomManager)
            async let _ = roomManager.run()
            try await Task.sleep(for: .milliseconds(1))
            let (roomCode, adminToken) = try await createRoom(on: self.roomHandler)
            self.roomCode = roomCode
            self.adminToken = adminToken
            self.questionID = try await QuestionTests.createQuestion(on: roomHandler, roomCode: roomCode, adminToken: adminToken)
        }

        @Test("[plurality] Can vote")
        func test_canVote_plurality() async throws {
            let participantToken = try await forceJoinRoom(on: roomHandler, roomCode: roomCode, adminToken: adminToken)
            try await Self.submitVote(
                on: roomHandler, 
                roomCode: roomCode, 
                questionID: questionID, 
                participantToken: participantToken, 
                vote: .PluralityVote(.init(
                    selection: QuestionTests.defaultQuestionOptions[0]
                ))
            )
        }

        @Test("[preferential] Can vote")
        func test_canVote_preferential() async throws {
            let participantToken = try await forceJoinRoom(on: roomHandler, roomCode: roomCode, adminToken: adminToken)
            try await Self.submitVote(
                on: roomHandler,
                roomCode: roomCode,
                questionID: questionID,
                participantToken: participantToken,
                vote: .PreferentialVote(.init(
                    selectionOrder: QuestionTests.defaultQuestionOptions
                ))
            )
        }

        static func submitVoteWithResponse(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            participantToken: String,
            vote: Components.Schemas.AnyVote
        ) async throws -> Operations.PostRoomVoteCodeQuestionID.Output {
            try await roomHandler.postRoomVoteCodeQuestionID(
                .init(
                    path: .init(
                        code: roomCode,
                        questionID: questionID
                    ),
                    headers: .init(
                        participantToken: participantToken
                    ),
                    body: .json(vote)
                )
            )
        }

        static func submitVote(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            questionID: String,
            participantToken: String,
            vote: Components.Schemas.AnyVote
        ) async throws {
            _ = try await submitVoteWithResponse(
                on: roomHandler,
                roomCode: roomCode,
                questionID: questionID,
                participantToken: participantToken,
                vote: vote
            )
            // TODO: Add more checks
        }

    }

}
