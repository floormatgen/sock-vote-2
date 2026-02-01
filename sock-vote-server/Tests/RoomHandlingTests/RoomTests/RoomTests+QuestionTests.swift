import Testing
@testable import RoomHandling

import VoteHandling

extension RoomTests {

    @Suite
    struct QuestionTests {
        let room: DefaultRoom

        init() async throws {
            self.room = try createRoom()
        }

        @Test("hasCurrentQuestion is false on creation")
        func test_hasCurrentQuestionIsFalseOnCreation() async throws {
            #expect(await !room.hasCurrentQuestion)
        }

        @Test("New room has no question description")
        func test_newRoomHasNoQuestionDescription() async throws {
            #expect(await room.currentQuestionDescription == nil)
        }

        @Test("Active question has accessable details")
        func test_activeQuestionHasAccessableDetails() async throws {
            try await Self.updateQuestion(on: room)
        }

        static var defaultPrompt: String {
            "Default Question Prompt"
        }

        static var defaultOptions: [String] {
            ["foo", "bar", "baz"]
        }

        static func updateQuestion(
            on room: DefaultRoom,
            prompt: String = Self.defaultPrompt,
            options: some Collection<String> & Sendable = Self.defaultOptions,
            style: Question.VotingStyle = .plurality
        ) async throws {
            try await room.updateQuestion(
                prompt: prompt, 
                options: options, 
                style: style
            )
            #expect(await room.hasCurrentQuestion)
            let description = try #require(await room.currentQuestionDescription)
            #expect(description.prompt == prompt)
            #expect(description.options == Array(options))
            #expect(description.votingStyle == style)
        }

    }


}
