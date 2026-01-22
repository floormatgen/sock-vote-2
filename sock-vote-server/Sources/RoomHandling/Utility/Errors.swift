package enum RoomError: Swift.Error {
    /// When a valid code could not be generated for a room
    case failedToGenerateCode

    var localizedDescription: String {
        switch self {
            case .failedToGenerateCode:
                return "An available room code could not be generated."
        }
    }
}
