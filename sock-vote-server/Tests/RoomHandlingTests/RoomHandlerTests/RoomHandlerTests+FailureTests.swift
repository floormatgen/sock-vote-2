import Testing
@testable import RoomHandling

extension RoomHandlerTests {

    @Suite
    struct FailureTests {

        @Test("Codegen failure handled gracefully")
        func test_failedToGenerateCode() async throws {
            let generator = ConstantRoomCodeGenerator(value: "123456")
            let roomManager = RoomManager(roomType: DefaultRoom.self, roomCodeGenerator: generator)
            let handler = RoomHandler(roomManager: roomManager)
            async let _ = roomManager.run()
            try await Task.sleep(for: .milliseconds(1))
            _ = try await handler.createRoom(withName: "Test Room")
            let response = try await handler.postRoomCreate(.init(body: .json(.init(name: "Fail Room"))))
            _ = try response.internalServerError
        }
        
        @Test("Nonexistent room returns not found")
        func test_infoForNonexistentRoomReturnsNotFound() async throws {
            let roomManager = DefaultRoomManager()
            let handler = DefaultRoomHandler(roomManager: roomManager)
            async let _ = roomManager.run()
            try await Task.sleep(for: .milliseconds(1))
            let response = try await handler.getRoomInfoCode(.init(path: .init(code: "123456")))
            guard case .notFound = response else {
                Issue.record("Did not return .notFound, instead: \(response)")
                return
            }
        }

    }

}
