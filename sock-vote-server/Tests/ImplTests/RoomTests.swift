import Testing
import Foundation
import HTTPTypes

@testable import App


@Suite("Room Tests")
struct RoomTests {

    struct ConstantGenerator: RoomCode.Generator {
        var limit: Int { 5 }
        let code: RoomCode.Code
        
        init(code: RoomCode.Code) {
            self.code = code
        }

        func next() -> RoomCode.Code {
            return code
        }
        
    }
    
    @Test("Generation throws at limit")
    func errorThrownWhenLimitExceeded() async throws {
        let repository = InMemoryRoomRepository(generator: ConstantGenerator(code: "676767"))
        _ = try await repository.addRoom(name: "First")
        await #expect(throws: RoomCode.FailedToGenerateError.self) {
            try await repository.addRoom(name: "Second")
        }
    }

    @Test("Generation failure has 500 status")
    func generationFailureHas500Status() async throws {
        let error = RoomCode.FailedToGenerateError()
        #expect(error.status == .internalServerError)
    }

}
