import Testing
@testable import SockVoteServer

import Configuration
import Hummingbird
import HummingbirdTesting

@Suite
struct ConnectionTests {
    let app: DefaultApplication

    init() async throws {
        let config = ConfigReader(provider: InMemoryProvider(values: [:]))
        let app = try await buildApplication(reader: config)
        self.app = app
        try await Task.sleep(for: .milliseconds(1))
    }

    // @Test("Participant connections receive question update")
    // func test_participantConnectionsReceiveQuestionUpdate() async throws {
    //     try await app.test(.live) { client in
            
    //     }
    // }

}
