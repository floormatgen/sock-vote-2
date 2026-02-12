import Hummingbird
import HummingbirdWebSocket
import NIOFoundationCompat
import AsyncAlgorithms
import VoteHandling

extension Connections {

    public typealias QuestionDescription = VoteHandling.Question.Description

    public protocol ParticipantConnection: Sendable {

        func sendQuestionUpdated(with description: QuestionDescription) async throws
        func sendQuestionDeleted() async throws
        func removeConnection()

    }
    
    public struct WebSocketParticipantConnection: ParticipantConnection {
        private let inboundMessageStream: WebSocketInboundMessageStream
        private let outboardWriter: WebSocketOutboundWriter

        public typealias OutputStream = AsyncChannel<WebSocketOutboundWriter.OutboundFrame>
        public let outputStream: OutputStream
    
        public init(
            inboundMessageStream: WebSocketInboundMessageStream, 
            outboardWriter: WebSocketOutboundWriter
        ) {
            self.inboundMessageStream = inboundMessageStream
            self.outboardWriter = outboardWriter
            self.outputStream = OutputStream()
        }

        public func sendQuestionUpdated(
            with description: QuestionDescription
        ) async throws {
            let message = QuestionUpdated(
                question: description
            )
            let buffer = try encoder.encodeAsByteBuffer(message, allocator:  allocator)
            await outputStream.send(.text(.init(buffer: buffer)))
        }

        public func sendQuestionDeleted() async throws {
            let message = QuestionRemoved()
            let buffer = try encoder.encodeAsByteBuffer(message, allocator: allocator)
            await outputStream.send(.text(.init(buffer: buffer)))
        }

        public func removeConnection() {
            outputStream.finish()
        }
    
    }


}

