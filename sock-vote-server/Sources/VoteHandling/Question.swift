import Foundation

@available(*, unavailable)
extension Question: @unchecked Sendable { }

/// An active question
package final class Question {

    /// The style of voting for the question
    package enum VotingStyle {
        case plurality
        case preferential
    }

    /// Immtable data about a question
    /// 
    /// This can be used to send information about a question through
    /// isolation domains, as ``Question`` is explicitly non-`Sendable`.
    package struct Description: Sendable {
        let id: UUID
        let prompt: String
        let options: [String]
        let style: VotingStyle
    }

    package let id: UUID
    package let prompt: String
    package let options: [String]
    private var votes: _VotesContainer

    package init(
        id: UUID = .init(),
        prompt: String,
        options: [String],
        votingStyle: VotingStyle
    ) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.votes = .init(votingStyle)
    }

    package var questionDescription: Description {
        .init(id: id, prompt: prompt, options: options, style: votingStyle)
    }

    package var votingStyle: VotingStyle {
        votes.votingStyle
    }

    package var voteCount: Int {
        votes.voteCount
    }

    package func hasVoted(participantToken: String) -> Bool {
        votes.hasVoted(participantToken: participantToken)
    }

    @discardableResult
    func registerPluralityVote(_ vote: PluralityVote, participantToken: String) throws -> VoteResult {
        try votes.registerPluralityVote(vote, participantToken: participantToken)
    }

    @discardableResult
    func registerPreferentialVote(_ vote: PreferentialVote, participantToken: String) throws -> VoteResult {
        try votes.registerPreferentialVote(vote, participantToken: participantToken)
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
                default:
                    throw Error.voteStyleMismatch(expected: .plurality, received: self.votingStyle)
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
                    throw Error.voteStyleMismatch(expected: .preferential, received: self.votingStyle)
            }
        }
        
    }

    package enum VoteResult {
        case initialVote
        case replacingVote

        internal init(replacing: Bool) {
            self = replacing ? .replacingVote : .initialVote
        }
    }

}

extension Question.VotingStyle: LosslessStringConvertible {

    package init?(_ description: some StringProtocol) {
        switch description {
            case "plurality": self = .plurality
            case "preferential": self = .preferential
            default: return nil
        }
    }

    package var description: String {
        switch self {
            case .plurality: "plurality"
            case .preferential: "preferential"
        }
    }

}