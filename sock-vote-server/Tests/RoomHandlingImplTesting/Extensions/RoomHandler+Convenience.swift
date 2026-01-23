import Testing
@testable import RoomHandling

extension RoomHandler {
    
    // MARK: - Route Utilities

    func createRoom(
        withName name: String,
        fields: [String]? = nil,
    ) async throws -> (name: String, code: String, fields: [String], adminToken: String) {
        let output = try await postRoomCreate(.init(body: .json(.init(name: name))))
        let body = try output.ok.body.json
        return (body.name, body.code, body.fields ?? [], body.adminToken)
    }

    func roomInfo(
        withCode code: String
    ) async throws -> (name: String, code: String) {
        let output = try await getRoomInfoCode(.init(path: .init(code: code)))
        let body = try output.ok.body.json
        return (body.name, body.code)
    }

    func joinRequests(
        withCode code: String,
        adminToken: String
    ) async throws -> [JoinRequest] {
        let output = try await getRoomJoinRequestsCode(.init(path: .init(code: code), headers: .init(roomAdminToken: adminToken)))
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
