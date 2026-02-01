import Testing
@testable import RoomHandling

import HTTPTypes

@available(*, deprecated, message: "Use convenience functions defined on test suites instead")
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

    func requestRoomJoin(
        withCode code: String,
        name: String, fields: [String : String]? = nil
    ) async throws -> String {
        let output = try await postRoomJoinCode(.init(path: .init(code: code), body: .json(.init(name: name, fields: .init(additionalProperties: fields ?? [:])))))
        let body = try output.ok.body.json
        return body.participantToken
    }

    func handleJoinRequests(
        withCode code: String,
        adminToken: String,
        accept: [String]? = nil,
        reject: [String]? = nil
    ) async throws -> (accepted: [String]?, rejected: [String]?, failed: [String]?, status: HTTPResponse.Status) {
        let output = try await postRoomJoinRequestsCode(.init(
            path: .init(code: code), 
            headers: .init(roomAdminToken: adminToken), 
            body: .json(.init(accept: accept, reject: reject))
        ))
        switch output {
            case .ok(let result):
                let body = try result.body.json
                return (body.accepted, body.rejected, body.failed, .ok)
            case .badRequest(let result):
                let body = try result.body.json
                return (body.accepted, body.rejected, body.failed, .badRequest)
            case .notFound:
                return (nil, nil, nil, .notFound)
            case .forbidden:
                return (nil, nil, nil, .forbidden)
            case .undocumented(let code, _):
                return (nil, nil, nil, .init(code: code))
        }

    }

    struct JoinRequest {
        var name: String
        var participantToken: String
        var timestamp: String
        var fields: [String : String]
    }
    
}
