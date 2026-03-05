import Hummingbird
import HummingbirdWebSocket
import HTTPTypes
import AsyncAlgorithms

extension Connections {

    public struct Routes<
        RoomManager: RoomManagerProtocol
    >: Sendable 
    where 
        RoomManager.Room.ParticipantConnection == WebSocketParticipantConnection 
    {
        public let roomManager: RoomManager

        public typealias Context = BasicWebSocketRequestContext

        public init(roomManager: RoomManager) {
            self.roomManager = roomManager
        }
        
        public var routes: RouteCollection<Context> {
            let routes = RouteCollection(context: Context.self)
            
            routes.ws(
                "room/:code/connect/participant",
                shouldUpgrade: self.shouldUpgradeParticipant(request:context:),
                onUpgrade: self.handleUpgradedParticipant(inbound:writer:context:)
            )
            
            return routes
        }

        // MARK: - Participant connections

        @Sendable
        internal func shouldUpgradeParticipant(
            request: Request, 
            context: Context
        ) async throws -> RouterShouldUpgrade {
            guard 
                let code = context.parameters.get("code"),
                let participantToken = request.headers[.participantToken],
                let room = await roomManager.room(withCode: code),
                await room.hasParticipant(withParticipantToken: participantToken)
            else {
                return .dontUpgrade
            }
            return .upgrade([:])
        }

        @Sendable
        internal func handleUpgradedParticipant(
            inbound: WebSocketInboundStream,
            writer: WebSocketOutboundWriter,
            context: WebSocketRouterContext<Context>
        ) async throws {
            guard
                let code = context.requestContext.parameters.get("code"),
                let participantToken = context.request.headers[.participantToken],
                let room = await roomManager.room(withCode: code)
            else {
                return
            }
            let connection = WebSocketParticipantConnection(
                inboundMessageStream: inbound.messages(maxSize: 1024), // Doesn't matter right now
                outboardWriter: writer
            )
            try await room.addParticipantConnection(connection, forParticipantToken: participantToken)
            let outputStream = connection.outputStream
            for await output in outputStream {
                try await writer.write(output)
            }
        }

    }

}

public extension HTTPField.Name {

    static let participantToken = HTTPField.Name("Participant-Token")!
    static let adminToken = HTTPField.Name("Room-Admin-Token")!

}
