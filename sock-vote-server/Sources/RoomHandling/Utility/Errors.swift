/// Errors related to rooms
public enum RoomError: Swift.Error, Equatable {
    /// When a valid code could not be generated for a room
    case failedToGenerateCode
    /// When a join request is missing required fields
    case invalidFields(missing: [String], extra: [String])
    /// Where there is no active question
    case missingQuestion

    var localizedDescription: String {
        switch self {
            case .failedToGenerateCode:
                "An available room code could not be generated"
            case .invalidFields(let missing, let extra):
                "Invalid fields: (missing: \(missing), extra: \(extra))"
            case .missingQuestion:
                "No active question."
        }
    }
}
