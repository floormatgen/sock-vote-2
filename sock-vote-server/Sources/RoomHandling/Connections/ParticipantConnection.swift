import Hummingbird
import HummingbirdWebSocket
import NIOFoundationCompat
import VoteHandling

extension Connections {

    public protocol ParticipantConnection: Sendable {

        func sendQuestionUpdate(with description: VoteHandling.Question.Description) async throws
        func sendQuestionRemove() async throws

    }
    
    public struct WebSocketParticipantConnection: ParticipantConnection {
        private let inboundStream: WebSocketInboundStream
        private let outboardWriter: WebSocketOutboundWriter
    
        public init(
            inboundStream: WebSocketInboundStream, 
            outboardWriter: WebSocketOutboundWriter
        ) {
            self.inboundStream = inboundStream
            self.outboardWriter = outboardWriter
        }

        public func sendQuestionUpdate(
            with description: VoteHandling.Question.Description
        ) async throws {
            let message = QuestionUpdated(
                question: description
            )
            let buffer = try encoder.encodeAsByteBuffer(message, allocator:  allocator)
            try await outboardWriter.write(.text(.init(buffer: buffer)))
        }

        public func sendQuestionRemove() async throws {
            let message = QuestionRemoved()
            let buffer = try encoder.encodeAsByteBuffer(message, allocator: allocator)
            try await outboardWriter.write(.text(.init(buffer: buffer)))
        }
    
    }


}

