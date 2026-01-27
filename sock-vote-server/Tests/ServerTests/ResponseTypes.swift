struct CreateRoomResponse: Codable {
    var name: String
    var code: String
    var adminToken: String
    var fields: [String]?
}

struct RoomInfoResponse: Codable {
    var name: String
    var fields: [String]?
}