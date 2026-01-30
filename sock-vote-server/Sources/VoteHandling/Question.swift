import Foundation

@available(*, unavailable)
extension Question: @unchecked Sendable { }

/// An active question
public final class Question {

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
        let id: UUID
        let prompt: String
        let options: [String]
        let style: VotingStyle
    }

    public let id: UUID
    public let prompt: String
    public let options: [String]
    public let optionsSet: Set<String>
    private var _votes: _VotesContainer

    /// Creates a new question
    /// 
    /// - Throws:
    ///     ``Question/Error/noOptions`` when `options` is empty
    public init(
        id: UUID = .init(),
        prompt: String,
        options: some Collection<String>,
        votingStyle: VotingStyle
    ) throws {
        guard options.count > 0 else {
            throw Error.noOptions
        }
        self.options = .init(options)
        self.optionsSet = .init(options)

        self.id = id
        self.prompt = prompt
        self._votes = .init(votingStyle)
    }

    public var questionDescription: Description {
        .init(id: id, prompt: prompt, options: options, style: votingStyle)
    }

    public var votingStyle: VotingStyle {
        _votes.votingStyle
    }

    public var voteCount: Int {
        _votes.voteCount
    }

    public func hasVoted(participantToken: String) -> Bool {
        _votes.hasVoted(participantToken: participantToken)
    }

    @discardableResult
    public func registerPluralityVote(_ vote: PluralityVote, participantToken: String) throws -> VoteResult {
        guard vote.validate(usingOptions: optionsSet) else { throw Error.invalidVote }
        let result = try _votes.registerPluralityVote(vote, participantToken: participantToken)
        _invalidateResultCache()
        return result
    }

    @discardableResult
    public func registerPreferentialVote(_ vote: PreferentialVote, participantToken: String) throws -> VoteResult {
        guard vote.validate(usingOptions: optionsSet) else { throw Error.invalidVote }
        let result = try _votes.registerPreferentialVote(vote, participantToken: participantToken)
        _invalidateResultCache()
        return result
    }

    internal enum _VotesContainer {
        case plurality([String : PluralityVote])
        case preferential([String : PreferentialVote])

        init(_ votingStyle: VotingStyle) {
            switch votingStyle {
                case .plurality: self = .plurality(.init())
                case .preferential: self = .preferential(.init())
            }
        }

        var votingStyle: VotingStyle {
            switch self {
                case .plurality: .plurality
                case .preferential: .preferential
            }
        }

        var voteCount: Int {
            switch self {
                case let .plurality(c): c.count
                case let .preferential(c): c.count
            }
        }

        func hasVoted(participantToken: String) -> Bool {
            switch self {
                case let .plurality(d): d.keys.contains(participantToken)
                case let .preferential(d): d.keys.contains(participantToken)
            }
        }

        @discardableResult
        mutating func registerPluralityVote(_ vote: PluralityVote, participantToken: String) throws -> VoteResult {
            switch self {
                case .plurality(var d):
                    let replacing = d.keys.contains(participantToken)
                    d[participantToken] = vote
                    self = .plurality(d)
                    return .init(replacing: replacing)
                case .preferential(_):
                    throw Error.voteStyleMismatch(expected: .preferential, received: .plurality)
            }
        }

        @discardableResult
        mutating func registerPreferentialVote(_ vote: PreferentialVote, participantToken: String) throws -> VoteResult {
            switch self {
                case .preferential(var d):
                    let replacing = d.keys.contains(participantToken)
                    d[participantToken] = vote
                    self = .preferential(d)
                    return .init(replacing: replacing)
                case .plurality(_):
                    throw Error.voteStyleMismatch(expected: .plurality, received: .preferential)
            }
        }
        
    }

    public enum VoteResult {
        case initialVote
        case replacingVote

        internal init(replacing: Bool) {
            self = replacing ? .replacingVote : .initialVote
        }
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
        switch _votes {
            case .plurality(let votes):
                return try Question.pluralityResult(using: votes.values, options: optionsSet)
            case .preferential(let votes):
                return try Question.preferentialResult(using: votes.values, options: optionsSet)
        }
    }

    public var result: Result {
        get throws {
            if let result = _resultCache { return result }
            try _updateResultCache()
            return _resultCache!
        }
    }

}

extension Question.VotingStyle: LosslessStringConvertible {

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

extension Question.VotingStyle: CaseIterable { }
