import Hummingbird
import HummingbirdWebSocket
import OpenAPIHummingbird
import RoomHandling
import Configuration

typealias DefaultApplication = Application<RouterResponder<BasicRequestContext>>

/// Build the default application using the provided options
func buildApplication(
    reader configReader: ConfigReader
) async throws -> DefaultApplication {
    let router = Router()

    let roomManager = DefaultRoomManager()
    let roomHTTPAPI = RoomHandler(roomManager: roomManager)
    try roomHTTPAPI.registerHandlers(on: router)

    let config = ApplicationConfiguration(reader: configReader)

    let webSocketRouter = Router(context: BasicWebSocketRequestContext.self)
    let connectionRoutes = Connections.Routes(roomManager: roomManager)
    connectionRoutes.addRoutes(to: webSocketRouter)

    var application = Application(
        router: router, 
        server: .http1WebSocketUpgrade(
            webSocketRouter: webSocketRouter
        ),
        configuration: config
    )

    application.addServices(roomManager)
    
    return application
}

extension Hummingbird.ApplicationConfiguration {

}
