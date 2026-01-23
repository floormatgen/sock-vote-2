/// Errors related to rooms
package enum RoomError: Swift.Error {
    /// When a valid code could not be generated for a room
    case failedToGenerateCode
    /// When a join request is missing required fields
    case invalidFields(missing: [String], extra: [String])

    var localizedDescription: String {
        switch self {
            case .failedToGenerateCode:
                return "An available room code could not be generated"
            case .invalidFields(let missing, let extra):
                return "Invalid fields: (missing: \(missing), extra: \(extra))"
        }
    }
}

extension RoomError: Equatable {

    package static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.failedToGenerateCode, .failedToGenerateCode):
                return true
            case let (.invalidFields(lm, le), .invalidFields(rm, re)):
                return (lm == rm && le == re)
            default:
                return false
        }
    }

}
