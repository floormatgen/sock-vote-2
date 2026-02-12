import Testing
@testable import RoomHandling

import Foundation

@Suite
struct RoomTests {

    static var defaultRoomName: String {
        "Room"
    }

    static var defaultFields: [String] {
        ["Student ID", "Email"]
    }

    static func createRoom(
        name: String = Self.defaultRoomName,
        fields: [String] = Self.defaultFields,
        code: String? = nil,
        adminToken: String? = nil,
        participantTimeout: Duration = .seconds(45),
        participantTimeoutFunction: @escaping Room.TimeoutFunction = DefaultRoom.defaultTimeoutFunction,
        joinRequestTimeout: Duration = .seconds(120),
        joinRequestTimeoutFunction: @escaping Room.TimeoutFunction = DefaultRoom.defaultTimeoutFunction
    ) throws -> DefaultRoom {
        let code = code ?? UUID().uuidString
        let adminToken = adminToken ?? UUID().uuidString
        let room = DefaultRoom(
            name: name, 
            code: code, 
            fields: fields, 
            adminToken: adminToken,
            participantTimeout: participantTimeout,
            participantTimeoutFunction: participantTimeoutFunction,
            joinRequestTimeout: joinRequestTimeout,
            joinRequestTimeoutFunction: joinRequestTimeoutFunction
        )
        #expect(room.code == code)
        #expect(room.verifyAdminToken(adminToken))
        #expect(room.name == name)
        #expect(room.fields == fields)
        return room
    }

    @discardableResult
    static func addParticipants(
        to room: some RoomProtocol,
        count: Int = 1
    ) async throws -> [String] {
        try await withThrowingTaskGroup { group in
            let fields = room.fields
            for i in 0..<count {
                group.addTask {
                    let name = "Participant \(i)"
                    let fields = Dictionary(
                        uniqueKeysWithValues: fields.map { key in
                            (key, UUID().uuidString)
                        }
                    )
                    _ = try await room.requestJoinRoom(name: name, fields: fields)
                }
            }
            try await Task.sleep(for: .milliseconds(1))
            let requests = await room.joinRequests
            let results = await room.handleJoinRequests(true, forTokens: requests.keys)
            return Array(results.keys)
        }
    }

}
