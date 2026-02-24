import Testing

import Hummingbird
import HummingbirdTesting
import Foundation
import NIOFoundationCompat
import RoomHandling

fileprivate let encoder = JSONEncoder()
fileprivate let decoder = JSONDecoder()

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
        #expect(response.status == 200)
        let responseBody = try decoder.decode(RoomInfoResponse.self, from: response.body)
        #expect(responseBody.code == code)
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
        var body = """
        {
            "name": "\(name)"
        """
        if let fields = fields {
            body += """
                , "fields": \(String(data: try encoder.encode(fields), encoding: .utf8) ?? "{}")
            }
            """
        } else {
            body += """
            }
            """
        }
        return try await self.execute(
            uri: "/room/\(code)/join", 
            method: .post,
            body: .init(string: body)
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
        #expect(response.status == 200)
        let responseBody = try decoder.decode(RoomJoinResponse.self, from: response.body)
        return responseBody.participantToken
    }

    func handleJoinRequestsWithResponse(
        code: String,
        adminToken: String,
        accept: [String]?,
        reject: [String]?
    ) async throws -> TestResponse {
        var body = """
        {
        """
        if let accept = accept {
            body += """
                "accept": \(try encoder.encode(accept)) 
            """
            if reject != nil {
                body += ", "
            }
        }
        if let reject = reject {
            body += """
                "reject": \(try encoder.encode(reject))
            """
        }
        body += """
        }
        """
        return try await self.execute(
            uri: "/room/\(code)/join-requests", 
            method: .post, 
            headers: [
                .adminToken : adminToken
            ], 
            body: .init(string: body)
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
        #expect(response.status == 200)
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
        #expect(response.status == 200)
        let responseBody = try decoder.decode(
            JoinRequestsResponse.self, 
            from: response.body
        )
        let timestamp = try Date.ISO8601FormatStyle().parse(responseBody.lastUpdated)
        #expect((Date.now - timestampWindow) <= timestamp && timestamp <= (Date.now + timestampWindow))
        return responseBody.requests
    }

    @discardableResult
    func forceJoinRoom(
        code: String,
        adminToken: String,
        name: String,
        fields: [String : String]? = nil,
    ) async throws -> [String : String] {
        async let participantToken = joinRoom(code: code, name: name, fields: fields)
        try await Task.sleep(for: .milliseconds(1))
        return [:]
    }

}

