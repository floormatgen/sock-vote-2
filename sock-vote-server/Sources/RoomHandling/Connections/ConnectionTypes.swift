import Foundation
import VoteHandling

// MARK: - Data Types

extension Connections {

    public enum PayloadType: String, Codable {
        case questionUpdated
        case questionDeleted
    }

    public struct BasePayload {
        var type: PayloadType
        var timestamp: Date

        public init(type: PayloadType, timestamp: Date = .now) {
            self.type = type
            self.timestamp = timestamp
        }
    }

    public typealias Question = VoteHandling.Question.Description

}

extension Connections.BasePayload: Codable {

    public enum CodingKeys: String, CodingKey {
        case type
        case timestamp
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp.ISO8601Format(), forKey: .timestamp)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(Connections.PayloadType.self, forKey: .type)
        let timestamp = try container.decode(String.self, forKey: .timestamp)
        let formatStyle = Date.ISO8601FormatStyle()
        self.timestamp = try formatStyle.parse(timestamp)
    }

}

// MARK: - Message Types

extension Connections {

    public struct QuestionUpdated {
        public var basePayload: BasePayload
        public var question: Question
    }

}

extension Connections.QuestionUpdated: Codable {

    public func encode(to encoder: any Encoder) throws {
        try basePayload.encode(to: encoder)
        try question.encode(to: encoder)
    }

    public init(from decoder: any Decoder) throws {
        self.basePayload = try .init(from: decoder)
        self.question = try .init(from: decoder)
    }

}
