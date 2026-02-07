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

}
