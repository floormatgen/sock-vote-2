import Hummingbird
import HummingbirdWebSocket
import HTTPTypes

struct ConnectionController<RoomManager: RoomManagerProtocol> {

    /// The context for websocket connection
    typealias Context = WebSocketRequestContext & RequestContext

    let roomManager: RoomManager
    
    init(roomManager: RoomManager) {
        self.roomManager = roomManager
    } 

    func addRoutes(to router: inout Router<some Context>) {

        router.ws(
            "room/connect/:code",
            shouldUpgrade: self.shouldUpgradeToConnection,
            onUpgrade: self.onUpgradeToConnection
        )

    }

    @Sendable
    func shouldUpgradeToConnection(
        request: Request,
        context: some Context
    ) async throws -> RouterShouldUpgrade {
        let code = try context.parameters.require("code")

        // Make sure the room actually exists
        let _ = try await roomManager.roomInfo(forCode: code)

        return .upgrade([:])
    }

    @Sendable
    func onUpgradeToConnection(
        inbound: WebSocketInboundStream,
        outbound: WebSocketOutboundWriter,
        context: WebSocketRouterContext<some Context>
    ) async throws {
        
    }

}

// MARK: - Errors

// extension ConnectionController {

//     enum Error: HTTPResponseError {

//         case missingCode

//         var status: HTTPResponse.Status {
//             switch self {
//             case .missingCode:
//                 return .badRequest
//             }
//         }

//         func response(
//             from request: HummingbirdCore.Request, context: some Hummingbird.RequestContext
//         ) throws -> Response {
//             return Response(status: self.status)
//         }

//     }

// }
