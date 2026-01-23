import Testing
@testable import RoomHandling

import Foundation

@Suite
struct RoomHandlerTests {
    let roomHandler: DefaultRoomHandler

    init() async throws {
        self.roomHandler = DefaultRoomHandler()
    }

    static var roomNames: [String] {[
        "UTS PCSoc Annual General Meeting",
        "BLÅHAJ committe meeting",
    ]}

    static var participantNames: [String] {[
        "John Person"
    ]}

    @Test("Room created with correct info", arguments: Self.roomNames)
    func test_roomCreatedWithCorrectInfo(_ name: String) async throws {
        let createOutput = try await roomHandler.postRoomCreate(.init(body: .json(.init(name: name))))
        let createName = try createOutput.ok.body.json.name
        let createCode = try createOutput.ok.body.json.code
        #expect(createName == name)
        let infoOutput = try await roomHandler.getRoomInfoCode(.init(path: .init(code: createCode)))
        let infoName = try infoOutput.ok.body.json.name
        let infoCode = try infoOutput.ok.body.json.code
        #expect(createName == infoName)
        #expect(createCode == infoCode)
    }

    @Test("Can attempt to join existing room", arguments: Self.participantNames)
    func test_canAttemptToJoinExistingRoom(_ name: String) async throws {
        let (_, code, _, adminToken) = try await createRoom(withName: "Room")
        Task.detached { 
            try await roomHandler.postRoomJoinCode(
                .init(path: .init(code: code), body: .json(.init(
                    name: name, 
                    fields: .init(additionalProperties: [:])
                )))
            ) 
        }
        try await Task.sleep(for: .milliseconds(10))
        let requests = try await joinRequests(withCode: code, adminToken: adminToken)
        let request = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(request.name == name)
        let date = try Utilities.parseTimestamp(request.timestamp)
        #expect(date.distance(to: .now) < 1)
    }

    // MARK: - Route Utilities

    func createRoom(
        withName name: String,
        fields: [String]? = nil,
    ) async throws -> (name: String, code: String, fields: [String], adminToken: String) {
        let output = try await roomHandler.postRoomCreate(.init(body: .json(.init(name: name))))
        let body = try output.ok.body.json
        return (body.name, body.code, body.fields ?? [], body.adminToken)
    }

    func roomInfo(
        withCode code: String
    ) async throws -> (name: String, code: String) {
        let output = try await roomHandler.getRoomInfoCode(.init(path: .init(code: code)))
        let body = try output.ok.body.json
        return (body.name, body.code)
    }

    func joinRequests(
        withCode code: String,
        adminToken: String
    ) async throws -> [JoinRequest] {
        let output = try await roomHandler.getRoomJoinRequestsCode(.init(path: .init(code: code), headers: .init(roomAdminToken: adminToken)))
        let body = try output.ok.body.json.requests
        return body.map { JoinRequest(name: $0.name, participantToken: $0.participantToken, timestamp: $0.timestamp, fields: $0.fields?.additionalProperties ?? [:]) }
    }

    struct JoinRequest {
        var name: String
        var participantToken: String
        var timestamp: String
        var fields: [String : String]
    }

}