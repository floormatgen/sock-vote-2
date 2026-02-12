import Testing
@testable import RoomHandling

import Foundation
import VoteHandling

extension RoomTests.ConnectionTests {

    @Suite
    final class QuestionUpdateTests: Sendable {
        let room: Room<MockParticipantConnection>
        let connectionTask: Task<Void, any Error>

        init() async throws {
            let adminToken = UUID().uuidString
            let room = Room<MockParticipantConnection>(
                name: "Room",
                code: "123456",
                fields: [],
                adminToken: adminToken
            )
            self.connectionTask = Task { try await room.runConnectionManager() }
            self.room = room
            try await Task.sleep(for: .milliseconds(1))
        }

        deinit {
            connectionTask.cancel()
        }

        @Test("Connections receive question update", arguments: [1, 10, 100, 1000])
        func test_questionUpdatesSentWhenQuestionUpdated(_ connectionCount: Int) async throws {
            let participantTokens = try await RoomTests.addParticipants(
                to: room, 
                count: connectionCount
            )
            let prompt = "Sample Prompt"
            let options = (0..<5).map(String.init)
            let style = Question.VotingStyle.plurality
            try await confirmation(expectedCount: connectionCount) { confirmation in
                await withThrowingTaskGroup { group in
                    for token in participantTokens {
                        var connection = MockParticipantConnection()
                        connection.sendQuestionUpdatedHandler = { question in
                            #expect(question.prompt == prompt)
                            #expect(question.options == options)
                            #expect(question.votingStyle == style) 
                            confirmation.confirm()
                        }
                        connection.sendQuestionDeletedHandler = {
                            Issue.record("Got sent deleted notification instead of question update")
                        }
                        group.addTask {
                            try await self.room.addParticipantConnection(connection, forParticipantToken: token)
                        }
                    }
                }
                try await room.updateQuestion(
                    prompt: prompt, 
                    options: options, 
                    style: style
                )
                try await Task.sleep(for: .milliseconds(10))
            }

        }

    }

}
