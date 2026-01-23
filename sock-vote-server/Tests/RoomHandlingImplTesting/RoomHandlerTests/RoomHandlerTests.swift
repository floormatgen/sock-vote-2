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
        let (_, code, _, adminToken) = try await roomHandler.createRoom(withName: "Room")
        Task.detached {
            try await roomHandler.postRoomJoinCode(
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
        #expect(date.distance(to: .now) < 1)
    }

}
