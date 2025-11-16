import Hummingbird
import HummingbirdWebSocket
import HTTPTypes

struct ConnectionController {

    /// The context for 
    typealias Context = WebSocketRequestContext & RequestContext

    struct ConnectionRequest: Decodable {
        let code: String
    }

    func addRoutes(to router: inout Router<some Context>) {

        router.ws(
            "room/connect",
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

        #warning("TODO: Make sure the code corresponds to an existing room.")

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
