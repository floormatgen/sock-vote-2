import Hummingbird
import HummingbirdTesting

extension TestClientProtocol {

    func createRoom(
        name: String, fields: [String]
    ) async throws -> TestResponse {
        return try await self.execute(
            uri: "/room/create", 
            method: .post, 
            body: .init(string: """
            { 
                "name": "\(name)",
                "fields": \(fields)
            }
            """)
        )
    }

    func roomInfo(
        withCode code: String
    ) async throws -> TestResponse {
        return try await self.execute(
            uri: "/room/\(code)/info",
            method: .get
        )
    }

}
