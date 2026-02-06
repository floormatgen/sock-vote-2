import Hummingbird
import Configuration

@main
struct EntryPoint {

    static func main() async throws {
        let config = ConfigReader(providers: [
            CommandLineArgumentsProvider(),
            EnvironmentVariablesProvider(),
        ])
        let application = try await buildApplication(reader: config)
        try await application.run()
    }

}
