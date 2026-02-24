import Testing
@testable import SockVoteServer

import Foundation
import NIOFoundationCompat
import Hummingbird
import HummingbirdTesting
import HTTPTypes
import Configuration

@Suite
final class RoomTests: Sendable {
    let app: DefaultApplication
    let appTask: Task<Void, any Error>

    static let decoder = JSONDecoder()
    // static let encoder = JSONEncoder()

    init() async throws {
        let configProvider = InMemoryProvider(values: [
            :
        ])
        self.app = try await buildApplication(reader: ConfigReader(provider: configProvider))
        self.appTask = Task { [app = self.app] in try await app.run() }
        try await Task.sleep(for: .milliseconds(1))
    }

    deinit {
        appTask.cancel()
    }
    
    @Test("Can create room")
    func test_canCreateRoom() async throws {
        try await app.test(.router) { client in
            let name = "abcd"
            let createResponse = try await client.createRoomWithResponse(name: name, fields: [])
            try #require(createResponse.status == .ok)
            let createData = try Self.decoder.decode(CreateRoomRequest.self, from: createResponse.body)
            #expect(createData.name == name)
            if let fields = createData.fields { #expect(fields.isEmpty) }
            let code = createData.code
            let infoResponse = try await client.roomInfoWithResponse(withCode: code)
            try #require(infoResponse.status == .ok)
            let infoData = try Self.decoder.decode(RoomInfoRequest.self, from: infoResponse.body)
            #expect(infoData.name == name)
            if let fields = createData.fields { #expect(fields.isEmpty) }
        }
    }

    @Test("Can create room with fields")
    func test_canCreateRoomWithFields() async throws {
        try await app.test(.router) { client in
            let name = "Room with fields"
            let fields = ["Student ID", "Email", "Phone Number"]
            let createResponse = try await client.createRoomWithResponse(name: name, fields: fields)
            try #require(createResponse.status == .ok)
            let createData = try Self.decoder.decode(CreateRoomRequest.self, from: createResponse.body)
            #expect(createData.name == name)
            #expect(createData.fields == fields)
            let code = createData.code
            let infoResponse = try await client.roomInfoWithResponse(withCode: code)
            try #require(infoResponse.status == .ok)
            let infoData = try Self.decoder.decode(RoomInfoRequest.self, from: infoResponse.body)
            #expect(infoData.name == name)
            #expect(infoData.fields == fields)
        }
    }

    @Test("Can get room info")
    func test_canGetRoomInfo() async throws {
        try await app.test(.router) { client in 
            let name = UUID().uuidString
            let fields = (0..<3).map(String.init).compactMap(UUID.init(uuidString:)).map(\.uuidString)
            let (creationCode, _) = try await client.createRoom(name: name, fields: fields)
            let (infoName, infoCode, infoFields) = try await client.roomInfo(withCode: creationCode)
            #expect(name == infoName)
            #expect(fields == infoFields)
            #expect(creationCode == infoCode)
        }
    }
    
}
