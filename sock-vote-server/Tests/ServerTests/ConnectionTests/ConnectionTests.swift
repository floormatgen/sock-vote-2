import Testing
@testable import SockVoteServer

import VoteHandling

import Foundation
import NIOFoundationCompat
import NIOWebSocket
import Configuration
import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import HummingbirdWSClient
import HummingbirdWSTesting

@Suite(.serialized)
struct ConnectionTests {
    let app: DefaultApplication
    let decoder: JSONDecoder
    
    init() async throws {
        let config = ConfigReader(provider: InMemoryProvider(values: [:]))
        let app = try await buildApplication(reader: config)
        self.app = app
        self.decoder = JSONDecoder()
        
        try await Task.sleep(for: .milliseconds(1))
    }

    @Test(
        "Participant connections receive question update",
//            .disabled("HummingbirdWSTesting bug"),
        arguments: [ 1 ]
    )
    func test_participantConnectionsReceiveQuestionUpdate(_ count: Int) async throws {
        let roomName                = "Room"
        let roomFields: [String]    = []
        
        let questionPrompt  = "Question \(UUID().uuidString)"
        let questionOptions = (0..<10).map(String.init)
        let questionStyle   = Question.VotingStyle.plurality
        do {
            try await app.test(.ahc()) { client in
                let (code, adminToken) = try await client.createRoom(name: roomName, fields: roomFields)
                let participantTokens = try await client.forceJoinRoom(
                    code: code,
                    adminToken: adminToken,
                    participants: (0..<count).map { n in
                        let name = "Participant \(n)"
                        return (name: name, fields: nil)
                    }
                )
                
                // Make sure all participants are connected
                
                try #require(participantTokens.count == count)
                try await withThrowingDiscardingTaskGroup { group in
                    try await confirmation { confirmation in
                        
                        // Connect each participant
                        for token in participantTokens {
                            group.addTask {
                                try await client.connectAsParticipant(
                                    code: code,
                                    token: token
                                ) { inbound, outbound, context in
                                    var seen = false
                                    for try await message in inbound.messages(maxSize: 1 << 16) {
                                        guard case let .binary(data) = message else {
                                            continue
                                        }
                                        try #require(!seen, "Question update sent multiple times to participant \(token)")
                                        seen = true
                                        let questionUpdate = try self.decoder.decode(
                                            Messages.QuestionUpdated.self,
                                            from: data
                                        )
                                        #expect(questionUpdate.prompt == questionPrompt)
                                        #expect(questionUpdate.options == questionOptions)
                                        #expect(questionUpdate.votingStyle == questionStyle.description)
                                        confirmation.confirm()
                                    }
                                }
                            }
                        }
                        
                        // Wait for all connections to be sent out
                        try await Task.sleep(for: .milliseconds(100 * count))
                        
                        // Update the current question
                        group.addTask {
                            try await client.updateQuestion(
                                code: code,
                                adminToken: adminToken,
                                prompt: questionPrompt,
                                options: questionOptions,
                                style: questionStyle
                            )
                        }
                        
                        // Wait for all updates to be sent out
                        try await Task.sleep(for: .milliseconds(100 * count))
                        group.cancelAll()
                    }
                }
            }
        } catch is CancellationError {
            // no-op
        }
    }

}
