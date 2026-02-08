import Testing
@testable import SockVoteServer

import Foundation
import NIOFoundationCompat
import HummingbirdTesting
import HTTPTypes
import Configuration

@Suite
struct RoomTests {
    let app: DefaultApplication

    static let decoder = JSONDecoder()
    // static let encoder = JSONEncoder()

    init() async throws {
        let configProvider = InMemoryProvider(values: [
            :
        ])
        self.app = try await buildApplication(reader: ConfigReader(provider: configProvider))
        try await Task.sleep(for: .milliseconds(1))
    }
    
    @Test("Can create room")
    func test_canCreateRoom() async throws {
        try await app.test(.router) { client in
            let name = "abcd"
            let createResponse = try await client.createRoom(name: name, fields: [])
            try #require(createResponse.status == .ok)
            let createData = try Self.decoder.decode(CreateRoomResponse.self, from: createResponse.body)
            #expect(createData.name == name)
            if let fields = createData.fields { #expect(fields.isEmpty) }
            let code = createData.code
            let infoResponse = try await client.roomInfo(withCode: code)
            try #require(infoResponse.status == .ok)
            let infoData = try Self.decoder.decode(RoomInfoResponse.self, from: infoResponse.body)
            #expect(infoData.name == name)
            if let fields = createData.fields { #expect(fields.isEmpty) }
        }
    }

    @Test("Can create room with fields")
    func test_canCreateRoomWithFields() async throws {
        try await app.test(.router) { client in
            let name = "Room with fields"
            let fields = ["Student ID", "Email", "Phone Number"]
            let createResponse = try await client.createRoom(name: name, fields: fields)
            try #require(createResponse.status == .ok)
            let createData = try Self.decoder.decode(CreateRoomResponse.self, from: createResponse.body)
            #expect(createData.name == name)
            #expect(createData.fields == fields)
            let code = createData.code
            let infoResponse = try await client.roomInfo(withCode: code)
            try #require(infoResponse.status == .ok)
            let infoData = try Self.decoder.decode(RoomInfoResponse.self, from: infoResponse.body)
            #expect(infoData.name == name)
            #expect(infoData.fields == fields)
        }
    }
    
}
