import Hummingbird
import HummingbirdWebSocket

extension Connections {

    public protocol ParticipantConnection: Sendable {
    
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
    
    }


}

