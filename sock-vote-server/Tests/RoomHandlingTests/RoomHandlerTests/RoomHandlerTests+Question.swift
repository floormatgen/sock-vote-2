import Testing
@testable import RoomHandling

import VoteHandling

extension RoomHandlerTests {

    @Suite
    struct QuestionTests {
        let roomHandler: DefaultRoomHandler

        init() async throws {
            roomHandler = DefaultRoomHandler()
        }

        @Test("Admin can create question")
        func test_adminCanCreateQuestion() async throws {
            let (code, adminToken) = try await createRoom(on: roomHandler)
            let prompt = "Question Prompt"
            let options = (0..<3).map { String($0) }

            let questionResponse = try await Self.createQuestion(
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

        static func createQuestion(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            adminToken: String,
            prompt: String = "Question",
            options: [String] = ["Option 1", "Option 2", "Option 3"],
            votingStyle: Question.VotingStyle = .plurality
        ) async throws -> Operations.PostRoomQuestionCode.Output {
            try await roomHandler.postRoomQuestionCode(.init(
                path: .init(code: roomCode),
                headers: .init(roomAdminToken: adminToken),
                body: .json(.init(
                    prompt: prompt, 
                    votingStyle: votingStyle.openAPIVotingStyle, 
                    options: options
                ))
            ))
        }

        // static func createQuestion(
        //     on roomHandler: RoomHandler<some RoomManagerProtocol>,
        //     roomCode: String,
        //     adminToken: String,
        //     prompt: String = "Question",
        //     options: [String] = ["Option 1", "Option 2", "Option 3"],
        //     votingStyle: Question.VotingStyle = .plurality
        // ) async throws {
        //     _ = try await createQuestionWithResponse(
        //         on: roomHandler, 
        //         roomCode: roomCode, 
        //         adminToken: adminToken, 
        //         prompt: prompt, 
        //         options: options, 
        //         votingStyle: votingStyle
        //     )
        // }

    }

}
