import Hummingbird
import OpenAPIHummingbird
import RoomHandling

typealias ApplicationType = Application<RouterResponder<BasicRequestContext>>

/// Build the default application using the provided options
func buildApplication(
    options: some OptionsProvider
) async throws -> ApplicationType {
    let router = Router()

    let roomHTTPAPI = RoomHandler()
    try roomHTTPAPI.registerHandlers(on: router)

    let config = ApplicationConfiguration(address: .hostname(options.hostname, port: options.port))
    let application = Application(router: router, configuration: config)
    
    return application
}
