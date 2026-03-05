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

struct JoinRoomRequest: Codable {
    var name: String
    var fields: [String: String]?
}

struct HandleJoinRequestRequest: Codable {
    var accept: [String]?
    var reject: [String]?
}

struct UpdateQuestionRequest: Codable {
    var prompt: String
    var options: [String]
    var style: String
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
    var fields: [String : String]?
}

struct QuestionUpdateResponse: Codable {
    var prompt: String
    var votingStyle: String
    var options: [String]
    var id: String
    var state: String
}

// MARK: - Connection Notifications

enum Messages {

    struct QuestionUpdated: Codable {
        var type: String
        var timestamp: String
        var id: String
        var prompt: String
        var votingStyle: String
        var options: [String]
        var state: String
    }

}

