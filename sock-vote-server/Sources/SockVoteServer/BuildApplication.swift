import Hummingbird
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
    var application = Application(router: router, configuration: config)
    application.addServices(roomManager)
    
    return application
}

extension Hummingbird.ApplicationConfiguration {

}
