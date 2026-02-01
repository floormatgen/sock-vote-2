import Testing
@testable import RoomHandling

import VoteHandling
import Foundation

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
            let (code, _) = try await createRoom(on: roomHandler)
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
            let (code, adminToken) = try await createRoom(on: roomHandler)
            try await Self.createQuestion(on: roomHandler, roomCode: code, adminToken: adminToken)
            try await Self.deleteQuestion(on: roomHandler, roomCode: code, adminToken: adminToken)
            #expect(try await !Self.checkQuestionExists(on: roomHandler, roomCode: code))
        }

        @Test("Admin cannot delete question from missing room")
        func test_adminCannotDeleteQuestionFromMissingRoom() async throws {
            let (code, adminToken) = try await createRoom(on: roomHandler)
            let id = try await Self.createQuestion(on: roomHandler, roomCode: code, adminToken: adminToken)
            let response = try await Self.deleteQuestionWithResponse(on: roomHandler, roomCode: "bad", adminToken: adminToken)
            #expect(throws: Never.self) { _ = try response.notFound }
            #expect(try await Self.checkQuestionExists(on: roomHandler, roomCode: code, id: id))
        }

        @Test("Cannot delete question with invalid admin token")
        func test_cannotDeleteQuestionWithInvalidAdminToken() async throws {
            let (code, adminToken) = try await createRoom(on: roomHandler)
            let id = try await Self.createQuestion(on: roomHandler, roomCode: code, adminToken: adminToken)
            let response = try await Self.deleteQuestionWithResponse(on: roomHandler, roomCode: code, adminToken: adminToken + "67")
            #expect(throws: Never.self) { _ = try response.forbidden }
            #expect(try await Self.checkQuestionExists(on: roomHandler, roomCode: code, id: id))
        }

        @Test("Cannot delete nonexistent question")
        func test_cannotDeleteNonexistentQuestion() async throws {
            let (code, adminToken) = try await createRoom(on: roomHandler)
            let response = try await Self.deleteQuestionWithResponse(on: roomHandler, roomCode: code, adminToken: adminToken)
            #expect(throws: Never.self) { _ = try response.badRequest }
            #expect(try await !Self.checkQuestionExists(on: roomHandler, roomCode: code))
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
            prompt: String = Self.defaultQuestionName,
            options: [String] = Self.defaultQuestionOptions,
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

        @discardableResult
        static func createQuestion(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            adminToken: String,
            prompt: String = Self.defaultQuestionName,
            options: [String] = Self.defaultQuestionOptions,
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
            let response = try await roomHandler.getRoomQuestionCode(
                .init(
                    path: .init(code: roomCode)
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
            adminToken: String
        ) async throws -> Operations.DeleteRoomQuestionCode.Output {
            try await roomHandler.deleteRoomQuestionCode(
                .init(
                    path: .init(code: roomCode), 
                    headers: .init(roomAdminToken: adminToken)
                )
            )
        }

        @discardableResult
        static func deleteQuestion(
            on roomHandler: RoomHandler<some RoomManagerProtocol>,
            roomCode: String,
            adminToken: String
        ) async throws -> Bool {
            let response = try await Self.deleteQuestionWithResponse(
                on: roomHandler, 
                roomCode: roomCode, 
                adminToken: adminToken
            )
            return switch response {
                case .ok: true
                default: false
            }
        }

    }

}
