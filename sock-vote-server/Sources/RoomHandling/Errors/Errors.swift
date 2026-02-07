/// Errors related to rooms
public enum RoomError: Swift.Error, Equatable {
    /// When a valid code could not be generated for a room
    case failedToGenerateCode
    /// When a join request is missing required fields
    case invalidFields(missing: [String], extra: [String])
    /// Where there is no active question
    case missingActiveQuestion
    /// The participant was not found
    case invaidParticipantToken(String)
    /// The participant associated with the token is already connected
    /// 
    /// Each registered participant may only have one active connection
    case alreadyConnected(participantToken: String)

    var localizedDescription: String {
        switch self {
            case .failedToGenerateCode:
                "An available room code could not be generated"
            case .invalidFields(let missing, let extra):
                "Invalid fields: (missing: \(missing), extra: \(extra))"
            case .missingActiveQuestion:
                "No active question"
            case .invaidParticipantToken(let token):
                "Invalid participant token \(token)"
            case .alreadyConnected(let token):
                "Participant with token \(token) is already connected"
        }
    }
}
