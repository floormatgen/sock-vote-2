import Foundation
import VoteHandling
import Logging

public protocol RoomProtocol: Actor {
    associatedtype ParticipantConnection: Connections.ParticipantConnection

    init(
        name: String, code: String, 
        fields: [String], adminToken: String,
        participantTimeout: Duration, joinRequestTimeout: Duration
    )

    nonisolated var name: String { get }
    nonisolated var code: String { get }
    nonisolated var fields: [String] { get }

    /// Active join requests
    var joinRequests: [String : JoinRequest] { get }

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
    nonisolated func verifyAdminToken(_ adminToken: String) -> Bool

    /// Handle a join request
    /// 
    /// - Parameter accept: Whether to accept the request
    /// - Parameter participantToken: The participant token to handle
    /// 
    func handleJoinRequest(_ accept: Bool, forToken participantToken: String) -> JoinRequestResult

    /// Whether the room has a current question
    /// 
    /// To remove a question, call ``removeQuestion()``
    var hasCurrentQuestion: Bool { get }

    /// Checks if the current room has a question matching the id provided
    func hasQuestion(with id: UUID) -> Bool

    /// Change the state of the current question
    func setCurrentQuestionState(to state: Question.State) throws

    /// The state of the current question
    var currentQuestionState: Question.State? { get }

    /// A description of the current question
    /// 
    /// - Returns: `nil` when ``hasCurrentQuestion`` is `false`
    var currentQuestionDescription: Question.Description? { get }

    /// The result of the current question
    /// 
    /// - Returns: `nil` when ``hasCurrentQuestion`` is `false`
    var currentQuestionResult: Question.Result? { get throws }

    /// The number of votes cast for the current question
    var currentQuestionVoteCount: Int? { get }

    /// Updates the question
    func updateQuestion(prompt: String, options: some Collection<String> & Sendable, style: Question.VotingStyle) throws

    /// Removes the current question
    /// 
    /// - Returns: `true` if a question was deleted, or `false` is there wasn't a question.
    @discardableResult
    func removeQuestion() throws -> Bool

    /// Whether the room has a participant with the specified token
    func hasParticipant(withParticipantToken participantToken: String) -> Bool

    func registerPluralityVote(
        _ vote: Question.PluralityVote, 
        forParticipant participantToken: String
    ) throws

    func registerPreferentialVote(
        _ vote: Question.PreferentialVote, 
        forParticipant participantToken: String
    ) throws

    // MARK: Handling Connections

    /// Run the connection manager associated with the room
    /// 
    /// This method will suspend until the room is closed,
    /// or when task cancellation or graceful shutdown is triggered.
    /// 
    nonisolated func runConnectionManager() async throws

    func addParticipantConnection(
        _ participantConnection: ParticipantConnection, 
        forParticipantToken participantToken: String
    ) throws

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
    nonisolated func validateFields(
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
  
    nonisolated func validateFieldKeys(
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
    nonisolated func validateFields(
        _ fields: [String : String],
    ) -> Bool {
        return validateFieldKeys(fields.keys)
    }

    nonisolated func validateFieldKeys(
        _ fieldKeys: some Collection<String>,
    ) -> Bool {
        guard fieldKeys.count == self.fields.count else { return false } // fastpath
        for field in self.fields {
            guard fieldKeys.contains(field) else { return false }
        }
        return true
    }

    /// - Throws:
    ///     ``VoteHanding/Question/Error/voteStyleMismatch`` when the vote type doesn't match the question.
    /// - Throws:
    ///     ``VoteHanding/Question/Error/invalidVote`` when the vote is invalid.
    func registerVote(
        _ vote: Components.Schemas.AnyVote,
        forParticipant participantToken: String
    ) throws {
        switch vote {
            case .PluralityVote(let v):
                try registerPluralityVote(.init(v), forParticipant: participantToken)
            case .PreferentialVote(let v):
                try registerPreferentialVote(.init(v), forParticipant: participantToken)
        }
    }

}

public typealias DefaultRoom = Room<Connections.WebSocketParticipantConnection>

public final actor Room<
    ParticipantConnection: Connections.ParticipantConnection
>: RoomProtocol {
    nonisolated public let name: String
    nonisolated public let code: String
    nonisolated public let fields: [String]

    nonisolated private let adminToken: String

    public typealias TimeoutFunction = @Sendable (Duration) async throws -> Void
    public static var defaultTimeoutFunction: TimeoutFunction { { try await Task.sleep(for: $0) } }

    // Join Requests
    public var joinRequests: [String : JoinRequest]
    private var joinRequestTimeouts: [String : Task<Void, any Swift.Error>]
    nonisolated public let joinRequestTimeout: Duration
    nonisolated private let joinRequestTimeoutFunction: TimeoutFunction

    // Inactive Participants
    private var inactiveParticipants: [String : Task<Void, any Swift.Error>]
    nonisolated public let participantTimeout: Duration
    nonisolated private let participantTimeoutFunction: TimeoutFunction

    // Active Participants
    private var activeParticipants: [String : ParticipantConnection]

    // Handling Connections
    nonisolated private let connectionManager: ConnectionManager

    public typealias Error = RoomError

    // TODO: Handle Participant and Admin connections

    private var currentQuestion: Question?

    public init(
        name: String, 
        code: String, 
        fields: [String], 
        adminToken: String,
        participantTimeout: Duration = .seconds(45),
        joinRequestTimeout: Duration = .seconds(120)
    ) {
        self.init(
            name: name, 
            code: code, 
            fields: fields, 
            adminToken: adminToken,
            participantTimeout: participantTimeout,
            participantTimeoutFunction: Self.defaultTimeoutFunction, 
            joinRequestTimeout: joinRequestTimeout,
            joinRequestTimeoutFunction: Self.defaultTimeoutFunction
        )
    }

    /// Creates a new room
    /// 
    /// > Important:
    /// > The `Task` that surrounds the ``participantTimeoutFunction`` and the ``joinRequestTimeoutFunction`` will be cancelled
    /// > if necessary, such as when a join request gets accepted or rejected.
    /// 
    internal init(
        name: String, 
        code: String, 
        fields: [String], 
        adminToken: String,
        participantTimeout: Duration,
        participantTimeoutFunction: @escaping TimeoutFunction,
        joinRequestTimeout: Duration,
        joinRequestTimeoutFunction: @escaping TimeoutFunction
    ) {
        self.name = name
        self.code = code
        self.fields = fields
        self.adminToken = adminToken
        self.joinRequests = [:]
        self.joinRequestTimeouts = [:]
        self.inactiveParticipants = [:]
        self.activeParticipants = [:]
        self.participantTimeout = participantTimeout
        self.participantTimeoutFunction = participantTimeoutFunction
        self.joinRequestTimeout = joinRequestTimeout
        self.joinRequestTimeoutFunction = joinRequestTimeoutFunction
        self.connectionManager = ConnectionManager(logger: Logger(label: "ConnectionManager(room: \(code))"))
    }

}

public extension Room {

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
            makeInactive(participantToken: participantToken)
            joinRequest.handleRequest(with: .success(participantToken: participantToken))
        } else {
            joinRequest.handleRequest(with: .rejected)
        }
        return .success
    }

    var hasCurrentQuestion: Bool {
        currentQuestion != nil
    }

    func hasQuestion(with id: UUID) -> Bool {
        currentQuestion?.id == id
    }

    var currentQuestionDescription: Question.Description? {
        currentQuestion?.questionDescription
    }

    func updateQuestion(prompt: String, options: some Collection<String> & Sendable, style: Question.VotingStyle) throws {
        let newQuestion = try Question.create(prompt: prompt, options: options, votingStyle: style)
        try sendQuestionUpdate(newQuestion)
        currentQuestion = newQuestion
    }

    func removeQuestion() throws -> Bool {
        if currentQuestion == nil { return false }
        currentQuestion = nil
        try sendQuestionUpdate(currentQuestion)
        return true
    }

    func setCurrentQuestionState(to newState: Question.State) throws {
        guard let question = self.currentQuestion else {
            throw Error.missingActiveQuestion
        }
        try question.setState(newState)
    }

    var currentQuestionState: Question.State? {
        guard let question = self.currentQuestion else { return nil }
        return question.state
    }

    var currentQuestionResult: Question.Result? {
        get throws {
            guard let question = self.currentQuestion else { return nil }
            return try question.result
        } 
    }

    var currentQuestionVoteCount: Int? {
        guard let question = self.currentQuestion else { return nil }
        return question.voteCount
    }

    func hasParticipant(withParticipantToken participantToken: String) -> Bool {
        return (
            activeParticipants.keys.contains(participantToken) ||
            inactiveParticipants.keys.contains(participantToken)
        )
    }

    func registerPluralityVote(
        _ vote: Question.PluralityVote, 
        forParticipant participantToken: String
    ) throws {
        guard let question = self.currentQuestion else {
            throw RoomError.missingActiveQuestion
        }
        try question.registerPluralityVote(vote, participantToken: participantToken)
    }

    func registerPreferentialVote(
        _ vote: Question.PreferentialVote, 
        forParticipant participantToken: String
    ) throws {
        guard let question = self.currentQuestion else {
            throw RoomError.missingActiveQuestion
        }
        try question.registerPreferentialVote(vote, participantToken: participantToken)
    }

    // MARK: - Handling Connections

    nonisolated func runConnectionManager() async throws {
        try await connectionManager.run()
    }

    func addParticipantConnection(
        _ participantConnection: ParticipantConnection, 
        forParticipantToken participantToken: String
    ) throws {
        assert(
            !(
                activeParticipants.keys.contains(participantToken) &&
                inactiveParticipants.keys.contains(participantToken)
            ),
            "\(#function): Participant \(participantToken) found to be active and inactive. This is not allowed."
        )
        guard !activeParticipants.keys.contains(participantToken) else {
            throw Error.alreadyConnected(participantToken: participantToken)
        }
        guard let timeout = inactiveParticipants.removeValue(forKey: participantToken) else {
            throw Error.invaidParticipantToken(participantToken)
        }
        assert(
            !timeout.isCancelled, 
            "\(#function): The timeout for participant \(participantToken) was cancelled but not removed"
        )
        timeout.cancel()
        activeParticipants[participantToken] = participantConnection
    }

}

/// MARK: - Sending Updates
private extension Room {

    func sendQuestionUpdate(_ question: Question?) throws {
        connectionManager.updateQuestion(question?.questionDescription)
    }

}

// MARK: - Private Helpers
private extension Room {

    func addJoinRequest(_ joinRequest: JoinRequest, participantToken: String) {
        joinRequests[participantToken] = joinRequest
        joinRequestTimeouts[participantToken] = Task {
            try await joinRequestTimeoutFunction(joinRequestTimeout)
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
