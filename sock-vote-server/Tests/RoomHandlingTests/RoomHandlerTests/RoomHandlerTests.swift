import Testing
@testable import RoomHandling

import Foundation
import HTTPTypes

@Suite
final class RoomHandlerTests: Sendable {
    let roomHandler: DefaultRoomHandler
    let managerTask: Task<Void, any Error>

    init() async throws {
        let roomManager = DefaultRoomManager()
        self.roomHandler = DefaultRoomHandler(roomManager: roomManager)
        self.managerTask = Task { try await roomManager.run() }
        try await Task.sleep(for: .milliseconds(1))
    }

    deinit {
        managerTask.cancel()
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
        let infoOutput = try await roomHandler.getRoomCodeInfo(.init(path: .init(code: createCode)))
        let infoName = try infoOutput.ok.body.json.name
        let infoCode = try infoOutput.ok.body.json.code
        #expect(createName == infoName)
        #expect(createCode == infoCode)
    }

    @Test("Can attempt to join existing room", arguments: Self.participantNames)
    func test_canAttemptToJoinExistingRoom(_ name: String) async throws {
        let (_, code, _, adminToken) = try await roomHandler.createRoom(withName: "Room")
        let joinRequestTask = Task.detached {
            try await self.roomHandler.postRoomCodeJoin(
                .init(path: .init(code: code), body: .json(.init(
                    name: name, 
                    fields: .init(additionalProperties: [:])
                )))
            ) 
        }
        try await Task.sleep(for: .milliseconds(10))
        let requests = try await roomHandler.joinRequests(withCode: code, adminToken: adminToken)
        let request = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(request.name == name)
        let date = try Utilities.parseTimestamp(request.timestamp)
        #expect(date.distance(to: .now) < 10 && date < .now)
        joinRequestTask.cancel()
    }

    @Test("Admin can accept join request")
    func test_adminCanAcceptJoinRequest() async throws {
        let name = "Foo"
        let (_, code, _, adminToken) = try await roomHandler.createRoom(withName: "Room")
        let participantTokenBox = Utilities.ActorBox<String?>(value: nil)
        try await confirmation { c in
            let requestJoinTask = Task {
                let participantToken = try await roomHandler.requestRoomJoin(withCode: code, name: name)
                await participantTokenBox.setValue(participantToken)
                c.confirm()
            }
            try await Task.sleep(for: .milliseconds(10))
            let requests = try await roomHandler.joinRequests(withCode: code, adminToken: adminToken)
            #expect(requests.count == 1)
            let request = try #require(requests.first)
            #expect(request.name == name)
            let date = try Utilities.parseTimestamp(request.timestamp)
            #expect(date.distance(to: .now) < 1 && date < .now)
            let participantToken = request.participantToken
            let (accepted, rejected, failed, status) = try await roomHandler.handleJoinRequests(
                withCode: code, adminToken: adminToken, 
                accept: [participantToken]
            )
            #expect(status == .ok)
            #expect(rejected?.isEmpty ?? true)
            #expect(failed?.isEmpty ?? true)
            try #require(accepted != nil)
            #expect(accepted!.count == 1)
            if let token = await participantTokenBox.value {
                #expect(token == participantToken)
            }
            try await Task.sleep(for: .milliseconds(10))
            requestJoinTask.cancel()
        }
    }

    // MARK: - Utility

    static func createRoomWithResponse(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        name: String = "Room",
        fields: [String]? = nil 
    ) async throws -> Operations.PostRoomCreate.Output {
        try await roomHandler.postRoomCreate(.init(body: .json(.init(
            name: name, fields: fields
        ))))
    }

    static func createRoom(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        name: String = "Room",
        fields: [String]? = nil 
    ) async throws -> (code: String, adminToken: String) {
        let response = try await createRoomWithResponse(on: roomHandler, name: name, fields: fields)
        let code = try response.ok.body.json.code
        let adminToken = try response.ok.body.json.adminToken
        return (code, adminToken)
    }

    static func handleJoinRequestsWithResponse(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        adminToken: String,
        accept: [String]? = [],
        reject: [String]? = []
    ) async throws -> Operations.PostRoomCodeJoinRequests.Output {
        try await roomHandler.postRoomCodeJoinRequests(
            .init(
                path: .init(
                    code: roomCode
                ), 
                headers: .init(
                    roomAdminToken: adminToken
                ), 
                body: .json(.init(
                    accept: accept, reject: reject
                ))
            )
        )
    }

    static func handleJoinRequest(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        adminToken: String,
        accept: [String]? = [],
        reject: [String]? = []
    ) async throws {
        let response = try await handleJoinRequestsWithResponse(
            on: roomHandler, 
            roomCode: roomCode, 
            adminToken: adminToken, 
            accept: accept, 
            reject: reject
        )
        let body = try response.ok.body.json
        #expect((body.accepted ?? []) == (accept ?? []))
        #expect((body.rejected ?? []) == (reject ?? []))
        #expect((body.failed ?? []).isEmpty)
    }

    static func listJoinRequestsWithResponse(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        adminToken: String
    ) async throws -> Operations.GetRoomCodeJoinRequests.Output {
        try await roomHandler.getRoomCodeJoinRequests(
            .init(
                path: .init(
                    code: roomCode
                ), 
                headers: .init(
                    roomAdminToken: adminToken
                )
            )
        )
    }

    typealias PendingJoinRequest = Operations.GetRoomCodeJoinRequests.Output.Ok.Body.JsonPayload.RequestsPayloadPayload

    static func listJoinRequests(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        adminToken: String
    ) async throws -> [PendingJoinRequest] {
        let response = try await listJoinRequestsWithResponse(
            on: roomHandler, 
            roomCode: roomCode, 
            adminToken: adminToken
        )
        let body = try response.ok.body.json
        return body.requests
    }

    static func joinRoomWithResponse(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        name: String = "Participant",
        fields: [String : String]? = nil
    ) async throws -> Operations.PostRoomCodeJoin.Output {
        try await roomHandler.postRoomCodeJoin(
            .init(
                path: .init(
                    code: roomCode
                ),
                body: .json(.init(
                    name: name,
                    fields: fields.map { .init(additionalProperties: $0) }
                ))
            )
        )
    }

    static func joinRoom(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        name: String = "Participant",
        fields: [String : String]? = nil
    ) async throws -> String {
        let response = try await joinRoomWithResponse(
            on: roomHandler, 
            roomCode: roomCode, 
            name: name, 
            fields: fields
        )
        let body = try response.ok.body.json
        return body.participantToken
    }

    static func forceJoinRoom(
        on roomHandler: RoomHandler<some RoomManagerProtocol>,
        roomCode: String,
        adminToken: String,
        name: String = "Participant",
        fields: [String : String]? = nil
    ) async throws -> String {
        async let returnedParticipantToken = joinRoom(
            on: roomHandler, 
            roomCode: roomCode, 
            name: name, 
            fields: fields
        )
        try await Task.sleep(for: .milliseconds(1))
        let requests = try await Self.listJoinRequests(
            on: roomHandler, 
            roomCode: roomCode, 
            adminToken: adminToken
        )
        let participantToken = try #require(requests.first { 
            $0.name == name &&
            $0.fields?.additionalProperties == fields
        }).participantToken
        try await Self.handleJoinRequest(
            on: roomHandler, 
            roomCode: roomCode, 
            adminToken: adminToken,
            accept: [participantToken]
        )
        #expect(try await participantToken == returnedParticipantToken)
        return participantToken
    }

}
