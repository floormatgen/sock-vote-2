import Hummingbird
import HummingbirdWebSocket
import Logging

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
package protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "SockVoteServer")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()
    
    let router = try buildRouter()
    let connectionRouter = try buildConnectionRouter()
    let app = Application(
        router: router,
        server: .http1WebSocketUpgrade(webSocketRouter: connectionRouter),
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "SockVoteServer"
        ),
        logger: logger
    )
    
    return app
}

/// Build router
func buildRouter() throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }

    // Route Registration
    let roomController = RoomController(repository: InMemoryRoomManager())
    router.addRoutes(roomController.routes, atPath: "/room")
    
    return router
}

/// Build Connection Router
func buildConnectionRouter() throws -> Router<BasicWebSocketRequestContext> {
    
    // Websocket handler registration
    let roomManager = InMemoryRoomManager()
    let wsController = ConnectionController(roomManager: roomManager)
    var wsRouter = Router(context: BasicWebSocketRequestContext.self)
    wsController.addRoutes(to: &wsRouter)
    
    return wsRouter
}
