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

    let roomHTTPAPI = RoomHandler()
    try roomHTTPAPI.registerHandlers(on: router)

    let config = ApplicationConfiguration(reader: configReader)
    let application = Application(router: router, configuration: config)
    
    return application
}

extension Hummingbird.ApplicationConfiguration {

}
