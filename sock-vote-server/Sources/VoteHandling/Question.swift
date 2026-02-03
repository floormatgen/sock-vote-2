import Foundation

@available(*, unavailable)
extension Question: @unchecked Sendable { }

/// An active question
public /* abstract */ class Question: Identifiable {

    /// The style of voting for the question
    public enum VotingStyle: Sendable {
        case plurality
        case preferential
    }

    /// Immtable data about a question
    /// 
    /// This can be used to send information about a question through
    /// isolation domains, as ``Question`` is explicitly non-`Sendable`.
    public struct Description: Sendable {
        public let id: UUID
        public let prompt: String
        public let options: [String]
        public let votingStyle: VotingStyle
    }

    public let id: UUID
    public let prompt: String
    public let options: [String]
    public let optionsSet: Set<String>

    /// Creates a new question
    /// 
    /// - Throws:
    ///     ``Question/Error/noOptions`` when `options` is empty
    public static func create(
        id: UUID = .init(),
        prompt: String,
        options: some Collection<String>,
        votingStyle: VotingStyle
    ) throws -> Question {
        switch votingStyle {
            case .plurality:
                return try PluralityQuestion(
                    id: id, prompt: prompt, options: options
                )
            case .preferential:
                return try PreferentialQuestion(
                    id: id, prompt: prompt, options: options
                )
        }
    }

    internal init(
        id: UUID = .init(),
        prompt: String,
        options: some Collection<String>
    ) throws {
        guard options.count > 0 else {
            throw Error.noOptions
        }
        self.options = .init(options)
        self.optionsSet = .init(options)

        self.id = id
        self.prompt = prompt
        #if DEBUG
        let meta = type(of: self as Any)
        precondition(meta != Question.self, "\(#function): Cannot create instace of abstract class Question")
        #endif
    }

    // MARK: - Question Information
    
    public enum VoteResult {
        case initialVote
        case replacingVote

        internal init(replacing: Bool) {
            self = replacing ? .replacingVote : .initialVote
        }
    }

    public var questionDescription: Description {
        .init(id: id, prompt: prompt, options: options, votingStyle: votingStyle)
    }

    public var votingStyle: VotingStyle {
        _requiresConcreteImplementation()
    }

    public var voteCount: Int {
        _requiresConcreteImplementation()
    }

    public func hasVoted(participantToken: String) -> Bool {
        _requiresConcreteImplementation()
    }

    // MARK: - Voting

    @discardableResult 
    public func registerPluralityVote(_ vote: PluralityVote, participantToken: String) throws -> VoteResult {
        guard let pluralityQuestion = self as? PluralityQuestion else {
            throw Error.voteStyleMismatch(expected: self.votingStyle, received: .plurality)
        }
        return try pluralityQuestion.registerVote(vote, participantToken: participantToken)
    }

    @discardableResult
    public func registerPreferentialVote(_ vote: PreferentialVote, participantToken: String) throws -> VoteResult {
        guard let preferentialQuestion = self as? PreferentialQuestion else {
            throw Error.voteStyleMismatch(expected: self.votingStyle, received: .preferential)
        }
        return try preferentialQuestion.registerVote(vote, participantToken: participantToken)
    }

    // MARK: - Handling Voting Results

    private var _resultCache: Result?

    private func _invalidateResultCache() {
        _resultCache = nil
    }

    private func _updateResultCache() throws {
        _resultCache = try _calculateVoteResult()
    }

    internal func _calculateVoteResult() throws -> Result {
        _requiresConcreteImplementation()
    }

    public var result: Result {
        get throws {
            if let result = _resultCache { return result }
            try _updateResultCache()
            return _resultCache!
        }
    }

    private func _requiresConcreteImplementation(
        function: StaticString = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Never {
        preconditionFailure(
            "\(function): Abstract method requires implmementation",
            file: file,
            line: line
        )
    }

}

extension Question.VotingStyle: LosslessStringConvertible, CaseIterable {

    public init?(_ description: some StringProtocol) {
        switch description {
            case "plurality": self = .plurality
            case "preferential": self = .preferential
            default: return nil
        }
    }

    public var description: String {
        switch self {
            case .plurality: "plurality"
            case .preferential: "preferential"
        }
    }

}

// MARK: - Custom Question Types

public final class PluralityQuestion: Question {
    private var _votes: [String : Vote]

    public typealias Vote = PluralityVote

    public override init(
        id: UUID = .init(), 
        prompt: String, 
        options: some Collection<String>
    ) throws {
        _votes = [:]
        try super.init(
            id: id, 
            prompt: prompt, 
            options: options
        )
    }

    public override var votingStyle: Question.VotingStyle {
        .plurality
    }

    public override var voteCount: Int {
        _votes.count
    }

    public override func hasVoted(participantToken: String) -> Bool {
        _votes.keys.contains(participantToken)
    }

    @discardableResult
    public func registerVote(_ vote: Vote, participantToken: String) throws -> VoteResult {
        guard vote.validate(usingOptions: optionsSet) else {
            throw Error.invalidVote
        }
        let replacing = _votes.keys.contains(participantToken)
        _votes[participantToken] = vote
        return .init(replacing: replacing)
    }

    internal override func _calculateVoteResult() throws -> Question.Result {
        return try Question.pluralityResult(using: _votes.values, options: optionsSet)
    }

}

public final class PreferentialQuestion: Question {
    private var _votes: [String : Vote]

    public typealias Vote = PreferentialVote

    public override init(
        id: UUID = .init(),
        prompt: String,
        options: some Collection<String>
    ) throws {
        _votes = [:]
        try super.init(
            id: id,
            prompt: prompt,
            options: options
        )
    }

    public override var votingStyle: Question.VotingStyle {
        .preferential
    }

    public override var voteCount: Int {
        _votes.count
    }

    public override func hasVoted(participantToken: String) -> Bool {
        _votes.keys.contains(participantToken)
    }

    @discardableResult
    public func registerVote(_ vote: Vote, participantToken: String) throws -> VoteResult {
        guard vote.validate(usingOptions: optionsSet) else {
            throw Error.invalidVote
        }
        let replacing = _votes.keys.contains(participantToken)
        _votes[participantToken] = vote
        return .init(replacing: replacing)
    }

    internal override func _calculateVoteResult() throws -> Question.Result {
        return try Question.preferentialResult(using: _votes.values, options: optionsSet)
    }

}
