import Foundation

package protocol RoomProtocol: AnyObject {
    var name: String { get }
    var code: String { get }
    var fields: [String] { get }

    /// Request to join the room
    /// 
    /// This request needs to be approved by an admin, this method will suspend until
    /// this request is accepted or rejected.
    /// 
    /// - Throws: ``RoomError/missingFields([String])`` if required fields are missing
    func requestJoinRoom(name: String, fields: [String : String]) async throws -> JoinResult
}

package extension RoomProtocol {

    /// Checks if provided fields are valid
    /// 
    /// This method uses the fields from ``RoomProtocol/fields``.
    /// 
    /// Fields are considered valid if they contain **exactly** the fields
    /// from ``RoomProtocol/fields``. Extra fields will make them invalid.
    /// 
    /// - Parameter fields: The fields to check
    /// - Parameter missingFields: On return the fields that were missing, if any
    /// - Parameter extraFields: On return the extra fields, if any
    /// 
    /// - Returns: `true` if the provided fields are valid, `false`` otherwise.
    func validateFields(
        _ fields: [String : String], 
        missingFields: inout [String], 
        extraFields: inout [String]
    ) -> Bool {
        var fieldsSet = Set(self.fields)
        for key in fields.keys {
            if fieldsSet.contains(key) {
                fieldsSet.remove(key)
            } else {
                extraFields.append(key)
            }
        }
        if fieldsSet.isEmpty, extraFields.isEmpty { return true }
        extraFields = Array(extraFields)
        return false
    }

    func validateFields(
        _ fields: [String : String],
    ) -> Bool {
        guard fields.count == self.fields.count else { return false } // fastpath
        for field in self.fields {
            guard fields.keys.contains(field) else { return false }
        }
        return true
    }

}

package final actor DefaultRoom: RoomProtocol {
    nonisolated package let name: String
    nonisolated package let code: String
    nonisolated package let fields: [String]

    nonisolated private let adminToken: String

    var joinRequests: [String : JoinRequest]

    init(name: String, code: String, fields: [String] = [], adminToken: String) {
        self.name = name
        self.code = code
        self.fields = fields
        self.adminToken = adminToken
        self.joinRequests = [:]
    }

}

package extension DefaultRoom {

    func requestJoinRoom(
        name: String, fields: [String : String]

    ) async throws -> JoinResult {
        var missingFields = [String]()
        var extraFields = [String]()
        guard validateFields(fields, missingFields: &missingFields, extraFields: &extraFields) else {
            throw RoomError.invalidFields(missing: missingFields, extra: extraFields)
        }
        let participantToken = UUID().uuidString
        do {
            try await withCheckedThrowingContinuation { continuation in
                let joinRequest = JoinRequest(name: name, fields: fields, continuation: continuation)
                addJoinRequest(joinRequest, participantToken: participantToken)
                fatalError()
            }
        } catch {
        }
        fatalError()
    }

}

// MARK: - Private Helpers
private extension DefaultRoom {

    func addJoinRequest(_ joinRequest: JoinRequest, participantToken: String) {
        joinRequests[participantToken] = joinRequest
        // TODO: Notify admin
    }

}

package struct JoinRequest {
    package typealias Continuation = CheckedContinuation<Bool, any Error>

    package var name: String
    package var fields: [String : String]
    package var timestamp: Date
    package var continuation: Continuation!

    package init(
        name: String, fields: [String : String],
        timestamp: Date = .now,
        continuation: Continuation
    ) {
        self.name = name
        self.fields = fields
        self.timestamp = timestamp
        self.continuation = continuation
    }
}

package enum JoinResult {
    case success(participantToken: String)
    case rejected
}