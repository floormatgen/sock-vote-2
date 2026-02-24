// MARK: - Requests

struct CreateRoomRequest: Codable {
    var name: String
    var code: String
    var adminToken: String
    var fields: [String]?
}

struct RoomInfoRequest: Codable {
    var name: String
    var fields: [String]?
}

// MARK: - Responses

struct CreateRoomResponse: Codable {
    var name: String
    var code: String
    var token: String
}

struct RoomInfoResponse: Codable {
    var name: String
    var code: String
    var fields: [String]
}

struct RoomJoinResponse: Codable {
    var participantToken: String
}

struct HandleJoinRequestsResponse: Codable {
    var accepted: [String]?
    var rejected: [String]?
    var failed: [String]?
}

struct JoinRequestsResponse: Codable {
    var lastUpdated: String
    var requests: [JoinRequestObject]
}

struct JoinRequestObject: Codable {
    var name: String
    var participantToken: String
    var timestamp: String
    var fields: [String : String]
}
