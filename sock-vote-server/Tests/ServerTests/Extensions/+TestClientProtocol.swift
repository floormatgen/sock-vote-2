import Testing

import VoteHandling

import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import HummingbirdWSClient
import HummingbirdWSTesting
import Foundation
import NIOFoundationCompat
import RoomHandling

fileprivate let encoder     = JSONEncoder()
fileprivate let decoder     = JSONDecoder()
fileprivate let allocator   = ByteBufferAllocator()

extension TestClientProtocol {

    func createRoomWithResponse(
        name: String, fields: [String]
    ) async throws -> TestResponse {
        try await self.execute(
            uri: "/room/create", 
            method: .post, 
            body: .init(string: """
            { 
                "name": "\(name)",
                "fields": \(fields)
            }
            """)
        )
    }

    func createRoom(
        name: String, fields: [String]
    ) async throws -> (code: String, adminToken: String) {
        let response = try await createRoomWithResponse(name: name, fields: fields)
        #expect(response.status == 200)
        let responseBody = try decoder.decode(CreateRoomRequest.self, from: response.body)
        #expect(responseBody.name == name)
        #expect(responseBody.fields == fields)
        let code = responseBody.code
        let adminToken = responseBody.adminToken
        return (code, adminToken)
    }

    func roomInfoWithResponse(
        withCode code: String
    ) async throws -> TestResponse {
        return try await self.execute(
            uri: "/room/\(code)/info",
            method: .get
        )
    }

    func roomInfo(
        withCode code: String
    ) async throws -> (name: String, code: String, fields: [String]) {
        let response = try await roomInfoWithResponse(withCode: code)
        try #require(response.status == 200)
        let responseBody = try decoder.decode(RoomInfoResponse.self, from: response.body)
        try #require(responseBody.code == code)
        let code = responseBody.code
        let name = responseBody.name
        let fields = responseBody.fields
        return (name, code, fields)
    }

    func joinRoomWithResponse(
        code: String,
        name: String,
        fields: [String : String]? = nil
    ) async throws -> TestResponse {
        return try await self.execute(
            uri: "/room/\(code)/join", 
            method: .post,
            body: encoder.encodeAsByteBuffer(
                JoinRoomRequest(
                    name: name,
                    fields: fields
                ),
                allocator: allocator
            )
        )
    }

    func joinRoom(
        code: String,
        name: String,
        fields: [String : String]? = nil
    ) async throws -> String {
        let response = try await joinRoomWithResponse(
            code: code, 
            name: name,
            fields: fields
        )
        try #require(response.status == 200)
        let responseBody = try decoder.decode(RoomJoinResponse.self, from: response.body)
        return responseBody.participantToken
    }

    func handleJoinRequestsWithResponse(
        code: String,
        adminToken: String,
        accept: [String]?,
        reject: [String]?
    ) async throws -> TestResponse {
        return try await self.execute(
            uri: "/room/\(code)/join-requests", 
            method: .post, 
            headers: [
                .adminToken : adminToken
            ], 
            body: encoder.encodeAsByteBuffer(
                HandleJoinRequestRequest(
                    accept: accept, 
                    reject: reject
                ), 
                allocator: allocator
            )
        )
    }

    @discardableResult
    func handleJoinRequest(
        code: String,
        adminToken: String,
        accept: [String]?,
        reject: [String]?
    ) async throws -> (accepted: [String]?, rejected: [String]?, failed: [String]?) {
        let response = try await handleJoinRequestsWithResponse(
            code: code, 
            adminToken: adminToken, 
            accept: accept, 
            reject: reject
        )
        try #require(response.status == 200)
        let responseBody = try decoder.decode(
            HandleJoinRequestsResponse.self, 
            from: response.body
        )
        let accepted    = responseBody.accepted
        let rejected    = responseBody.rejected
        let failed      = responseBody.failed
        #expect((accept ?? []) == (accepted ?? []))
        #expect((reject ?? []) == (rejected ?? []))
        #expect((responseBody.failed ?? []).isEmpty)
        return (accepted, rejected, failed)
    }

    func getJoinRequestsWithResponse(
        code: String,
        adminToken: String
    ) async throws -> TestResponse {
        try await self.execute(
            uri: "/room/\(code)/join-requests", 
            method: .get,
            headers: [
                .adminToken: adminToken
            ]
        )
    }

    @discardableResult
    func getJoinRequests(
        code: String,
        adminToken: String,
        timestampWindow: TimeInterval = 1
    ) async throws -> [JoinRequestObject] {
        let response = try await getJoinRequestsWithResponse(
            code: code, 
            adminToken: adminToken
        )
        try #require(response.status == 200)
        let responseBody = try decoder.decode(
            JoinRequestsResponse.self,
            from: response.body
        )
//        let timestamp = try Date.ISO8601FormatStyle().parse(responseBody.lastUpdated)
//        #expect((Date.now - timestampWindow) <= timestamp && timestamp <= (Date.now + timestampWindow))
        return responseBody.requests
    }

    func forceJoinRoom(
        code: String,
        adminToken: String,
        participants: some Collection<(name: String, fields: [String : String]?)>
    ) async throws -> [String] {
        try await withThrowingTaskGroup { group in
            for (name, fields) in participants {
                group.addTask(name: "Join request for participant: \"\(name)\"") {
                    try await joinRoom(code: code, name: name, fields: fields)
                }
            }
            try await Task.sleep(for: .milliseconds(participants.count))
            let requests = try await getJoinRequests(code: code, adminToken: adminToken)
            try #require(requests.count >= participants.count)
            let names = Set(participants.map(\.name))
            let participantTokens = requests.filter { names.contains($0.name) } .map(\.participantToken)
            try await handleJoinRequest(code: code, adminToken: adminToken, accept: participantTokens, reject: nil)
            var acceptedTokens: [String] = []
            acceptedTokens.reserveCapacity(participants.count)
            for try await participantToken in group {
                acceptedTokens.append(participantToken)
            }
            return acceptedTokens
        }
    }
    
    @discardableResult
    func forceJoinRoom(
        code: String,
        adminToken: String,
        name: String,
        fields: [String : String]?
    ) async throws -> String! {
        try await forceJoinRoom(
            code: code,
            adminToken: adminToken,
            participants: CollectionOfOne((name: name, fields: fields))
        ).first
    }
    
    // MARK: - Questions
    
    func updateQuestionWithResponse(
        code: String,
        adminToken: String,
        prompt: String,
        options: [String],
        style: Question.VotingStyle
    ) async throws -> TestResponse {
        try await self.executeRequest(
            uri: "room/\(code)/question",
            method: .post,
            headers: [
                .adminToken: adminToken
            ],
            body: encoder.encodeAsByteBuffer(
                UpdateQuestionRequest(
                    prompt: prompt,
                    options: options,
                    style: style.description
                ),
                allocator: allocator
            )
        )
    }
    
    @discardableResult
    func updateQuestion(
        code: String,
        adminToken: String,
        prompt: String,
        options: [String],
        style: Question.VotingStyle
    ) async throws -> String {
        let response = try await updateQuestionWithResponse(
            code: code,
            adminToken: adminToken,
            prompt: prompt,
            options: options,
            style: style
        )
        try #require(response.status == 200)
        let body = try decoder.decode(
            QuestionUpdateResponse.self,
            from: response.body
        )
        #expect(prompt == body.prompt)
        #expect(options == body.options)
        #expect(style == Question.VotingStyle(body.votingStyle))
        return body.id
    }
    
    // MARK: - Connections
    
    func connectAsParticipant(
        code: String,
        token: String,
        handler: @escaping WebSocketDataHandler<WebSocketClient.Context>
    ) async throws {
        try await self.ws(
            "/room/\(code)/connect/participant",
            configuration: .init(
                additionalHeaders: [
                    .participantToken: token
                ]
            ),
            handler: handler
        )
    }

}

