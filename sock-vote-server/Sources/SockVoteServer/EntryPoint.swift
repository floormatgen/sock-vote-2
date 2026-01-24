import ArgumentParser
import Hummingbird

@main
struct EntryPoint: AsyncParsableCommand, OptionsProvider {

    @Option(help: "The hostname of the server.")
    var hostname: String = "127.0.0.1"

    @Option(help: "The port of the server.")
    var port: Int = 8080

    func run() async throws {
        let application = try await buildApplication(options: self)
        try await application.run()
    }

}