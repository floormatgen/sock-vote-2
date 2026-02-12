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

        public typealias Context = WebSocketRequestContext & RequestContext

        public init(roomManager: RoomManager) {
            self.roomManager = roomManager
        }

        public func addRoutes(
            to webSocketRouter: Router<some Context>
        ) {

            webSocketRouter.ws(
                "room/connect/:code/participant", 
                shouldUpgrade: self.shouldUpgradeParticipant(request:context:), 
                onUpgrade: self.handleUpgradedParticipant(inbound:writer:context:)
            )

        }

        // MARK: - Participant connections

        @Sendable
        internal func shouldUpgradeParticipant(
            request: Request, 
            context: some Context
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
            context: WebSocketRouterContext<some Context>
        ) async throws {
            guard
                let code = context.requestContext.parameters.get("code"),
                let participantToken = context.request.headers[.participantToken],
                let room = await roomManager.room(withCode: code)
            else {
                return
            }
            let connection = WebSocketParticipantConnection(
                inboundMessageStream: inbound.messages(maxSize: 1024), 
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

}
