import Foundation
import Hummingbird
import HummingbirdTesting
import NIOCore
import NIOFoundationCompat
import Testing

@testable import App

@Suite("Room Tests")
struct RoomTests {

    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
    static let allocator = ByteBufferAllocator()

    let app: any ApplicationProtocol

    init() async throws {
        self.app = try await buildApplication(AppTests.TestArguments())
    }

    // MARK: - Utilities

    struct RoomCreationRequest: Encodable {
        let name: String
    }

    static func createRoom(
        withName name: String,
        client: any TestClientProtocol
    ) async throws -> TestResponse {
        let request = RoomCreationRequest(name: name)
        return try await client.execute(
            uri: "/room", method: .post,
            body: Self.encoder.encodeAsByteBuffer(request, allocator: Self.allocator))
    }

    static func getRoomInfo(
        withCode code: String,
        client: any TestClientProtocol
    ) async throws -> TestResponse {
        return try await client.execute(uri: "/room/\(code)", method: .get)
    }

    /// This method returns the public info of a room after getting it
    static func roundTripCreateRoom(
        withName name: String,
        client: any TestClientProtocol
    ) async throws -> (response: TestResponse, code: String) {
        let creationResponse = try await Self.createRoom(withName: name, client: client)
        #expect(creationResponse.status == .ok)
        let creationInfo = try Self.decoder.decode(FullRoomInfo.self, from: creationResponse.body)
        #expect(creationInfo.name == name)
        let code = creationInfo.code
        return (response: try await Self.getRoomInfo(withCode: code, client: client), code: code)
    }

    // MARK: - Tests

    @Test("Room can be created")
    func roomCanBeCreated() async throws {
        let name = "Foo"
        try await app.test(.router) { client in
            let response = try await Self.createRoom(withName: name, client: client)
            #expect(response.status == .ok)
            let info = try Self.decoder.decode(FullRoomInfo.self, from: response.body)
            #expect(info.name == name)
        }
    }

    @Test("Room can be found after creation")
    func roomCanBeFoundAfterCreation() async throws {
        let name = "Bar"
        try await app.test(.router) { client in
            let (response, code) = try await Self.roundTripCreateRoom(withName: name, client: client)
            let roomInfo = try Self.decoder.decode(RoomInfo.self, from: response.body)
            #expect(roomInfo.name == name)
            #expect(roomInfo.code == code)
        }
    }

    @Test("Room info only contains required properties")
    func roomInfoDoesNotContainAToken() async throws {
        let name = "Baz"
        try await app.test(.router) { client in 
            let (response, _) = try await Self.roundTripCreateRoom(withName: name, client: client)
            let json = try JSONSerialization.jsonObject(with: response.body)
            let topLevelDict = try #require(json as? [String: Any])
            #expect(Set(topLevelDict.keys) == ["name", "code"])
        }
    }

    @Test("Room info for nonexistent rooms cannot be found")
    func roomInfoForNonexistentRoomCannotBeFound() async throws {
        let name = "Mango"
        try await app.test(.router) { client in 
            let createResponse = try await Self.createRoom(withName: name, client: client)
            #expect(createResponse.status == .ok)
            let info = try Self.decoder.decode(FullRoomInfo.self, from: createResponse.body)
            var code = try #require(Int(info.code))
            code = (code + 1) % 1_000_000
            let invalid = Room.codeFormat.format(code)
            let getResponse = try await Self.getRoomInfo(withCode: invalid, client: client)
            #expect(getResponse.status == .notFound)
        }
    }

}
