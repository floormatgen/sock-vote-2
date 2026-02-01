import Foundation
import VoteHandling

public protocol RoomProtocol: AnyObject {
    var name: String { get }
    var code: String { get }
    var fields: [String] { get }

    var joinRequests: [String : JoinRequest] { get async }

    /// Request to join the room
    /// 
    /// This request needs to be approved by an admin, this method will suspend until
    /// this request is accepted or rejected.
    /// 
    /// - Throws: ``RoomError/invalidFields(missing:extra:)`` if required fields are missing
    func requestJoinRoom(name: String, fields: [String : String]) async throws -> JoinResult

    /// Verify a provided admin token
    /// 
    /// - Returns: `true` if the token is valid, otherwise `false`
    func verifyAdminToken(_ adminToken: String) -> Bool

    /// Handle a join request
    /// 
    /// - Parameter accept: Whether to accept the request
    /// - Parameter participantToken: The participant token to handle
    /// 
    func handleJoinRequest(_ accept: Bool, forToken participantToken: String) async -> JoinRequestResult

    /// Whether the room has a current question
    /// 
    /// To remove a question, call ``removeQuestion()``
    var hasCurrentQuestion: Bool { get async }

    /// A description of the current question
    /// 
    /// Returns `nil` when ``hasCurrentQuestion`` is `false`
    var currentQuestionDescription: Question.Description? { get async }

    /// Updates the question
    func updateQuestion(prompt: String, options: some Collection<String> & Sendable, style: Question.VotingStyle) async throws

    /// Removes the current question
    /// 
    /// - Returns: `true` if a question was deleted, or `false` is there wasn't a question.
    @discardableResult
    func removeQuestion() async throws -> Bool
}

public extension RoomProtocol {

    // MARK: Field Validation

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
        return validateFieldKeys(
            fields.keys, 
            missingFields: &missingFields, 
            extraFields: &extraFields
        )
    }
  
    func validateFieldKeys(
        _ fieldKeys: some Collection<String>,
        missingFields: inout [String],
        extraFields: inout [String]
    ) -> Bool {
        missingFields = []
        extraFields = []
        var fieldsSet = Set(self.fields)
        for key in fieldKeys {
            if fieldsSet.contains(key) {
                fieldsSet.remove(key)
            } else {
                extraFields.append(key)
            }
        }
        if fieldsSet.isEmpty, extraFields.isEmpty { return true }
        missingFields = Array(fieldsSet)
        return false
    }

    /// Checks if the provided fields arae valid
    /// 
    /// ``validateFields(_:missingFields:extraFields:)``
    func validateFields(
        _ fields: [String : String],
    ) -> Bool {
        return validateFieldKeys(fields.keys)
    }

    func validateFieldKeys(
        _ fieldKeys: some Collection<String>,
    ) -> Bool {
        guard fieldKeys.count == self.fields.count else { return false } // fastpath
        for field in self.fields {
            guard fieldKeys.contains(field) else { return false }
        }
        return true
    }

}

public final actor DefaultRoom: RoomProtocol {
    nonisolated public let name: String
    nonisolated public let code: String
    nonisolated public let fields: [String]

    nonisolated private let adminToken: String

    public typealias TimeoutFunction = @Sendable (Duration) async throws -> Void

    public var joinRequests: [String : JoinRequest]
    private var joinRequestTimeouts: [String : Task<Void, any Error>]
    nonisolated private let joinRequestTimeout: Duration
    nonisolated private let joinRequestTimeoutFunction: TimeoutFunction

    private var inactiveParticipants: [String : Task<Void, any Error>]
    nonisolated private let participantTimeout: Duration
    nonisolated private let participantTimeoutFunction: TimeoutFunction

    private var currentQuestion: Question?

    /// Creates a new room
    /// 
    /// > Important:
    /// > The `Task` that surrounds the ``participantTimeoutFunction`` and the ``joinRequestTimeoutFunction`` will be cancelled
    /// > if necessary, such as when a join request gets accepted or rejected.
    /// 
    public init(
        name: String, 
        code: String, 
        fields: [String], 
        adminToken: String,
        participantTimeout: Duration = .seconds(45),
        participantTimeoutFunction: @escaping TimeoutFunction = { try await Task.sleep(for: $0) },
        joinRequestTimeout: Duration = .seconds(120),
        joinRequestTimeoutFunction: @escaping TimeoutFunction = { try await Task.sleep(for: $0) }
    ) {
        self.name = name
        self.code = code
        self.fields = fields
        self.adminToken = adminToken
        self.joinRequests = [:]
        self.joinRequestTimeouts = [:]
        self.inactiveParticipants = [:]
        self.participantTimeout = participantTimeout
        self.participantTimeoutFunction = participantTimeoutFunction
        self.joinRequestTimeout = joinRequestTimeout
        self.joinRequestTimeoutFunction = joinRequestTimeoutFunction
    }

}

public extension DefaultRoom {

    func requestJoinRoom(
        name: String, fields: [String : String]
    ) async throws -> JoinResult {
        var missingFields = [String]()
        var extraFields = [String]()
        guard validateFields(fields, missingFields: &missingFields, extraFields: &extraFields) else {
            throw RoomError.invalidFields(missing: missingFields, extra: extraFields)
        }
        // TODO: Find a better way to generate tokens
        let participantToken = UUID().uuidString
        return try await withCheckedThrowingContinuation { continuation in
            let joinRequest = JoinRequest(name: name, fields: fields, continuation: continuation)
            addJoinRequest(joinRequest, participantToken: participantToken)
        }
    }

    nonisolated func verifyAdminToken(_ adminToken: String) -> Bool {
        return self.adminToken == adminToken
    }

    func handleJoinRequest(_ accept: Bool, forToken participantToken: String) -> JoinRequestResult {
        guard var joinRequest = joinRequests[participantToken] else {
            // TODO: Check active and inactive participants
            return .missing
        }
        joinRequests.removeValue(forKey: participantToken)
        if accept {
            joinRequest.handleRequest(with: .success(participantToken: participantToken))
        } else {
            joinRequest.handleRequest(with: .rejected)
        }
        return .success
    }

    var hasCurrentQuestion: Bool {
        currentQuestion != nil
    }

    var currentQuestionDescription: Question.Description? {
        currentQuestion?.questionDescription
    }

    func updateQuestion(prompt: String, options: some Collection<String> & Sendable, style: Question.VotingStyle) async throws {
        let newQuestion = try Question(prompt: prompt, options: options, votingStyle: style)
        currentQuestion = newQuestion
    }

    func removeQuestion() async throws -> Bool {
        if currentQuestion == nil { return false }
        currentQuestion = nil
        return true
    }

}

// MARK: - Private Helpers
private extension DefaultRoom {

    func addJoinRequest(_ joinRequest: JoinRequest, participantToken: String) {
        joinRequests[participantToken] = joinRequest
        joinRequestTimeouts[participantToken] = Task {
            try await participantTimeoutFunction(participantTimeout)
            if var request = joinRequests[participantToken] {
                request.handleRequest(with: .timeout)
                joinRequests.removeValue(forKey: participantToken)
            }
        }
        // TODO: Notify admin
    }

    func makeInactive(participantToken: String) {
        assert(!joinRequests.keys.contains(participantToken))
        assert(!inactiveParticipants.keys.contains(participantToken))

        let timeout = Task {
            try await participantTimeoutFunction(participantTimeout)
            assert(inactiveParticipants.keys.contains(participantToken))
            inactiveParticipants.removeValue(forKey: participantToken)
        }

        inactiveParticipants[participantToken] = timeout
    }

    func makeActive(participantToken: String) {
        assert(!joinRequests.keys.contains(participantToken))
    }

}

public struct JoinRequest: Sendable {
    public typealias Continuation = CheckedContinuation<JoinResult, any Error>

    public var name: String
    public var fields: [String : String]
    public var timestamp: Date
    private var continuation: Continuation!

    public init(
        name: String, fields: [String : String],
        timestamp: Date = .now,
        continuation: Continuation
    ) {
        self.name = name
        self.fields = fields
        self.timestamp = timestamp
        self.continuation = continuation
    }

    mutating func handleRequest(with result: JoinResult) {
        precondition(continuation != nil, "\(#function): Cannot handle request more than once.")
        continuation.resume(returning: result)
        continuation = nil
    }

}

public enum JoinResult: Sendable {
    case success(participantToken: String)
    case roomClosing
    case rejected
    case timeout
}

public enum JoinRequestResult: Sendable {
    /// The participant was accepted or rejected successfully
    case success
    /// The participant doesn't exist in the room
    case missing
    /// The participant was already accepted
    /// 
    /// The participant is in the active or inactive state
    case alreadyAccepted
}
