import ArgumentParser

@main
struct EntryPoint: AsyncParsableCommand, OptionsProvider {

    @Option(help: "The hostname of the server.")
    var hostname: String

    @Option(help: "The port of the server.")
    var port: Int

    func run() async throws {
        
    }

}