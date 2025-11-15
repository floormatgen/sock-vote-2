import Testing
import Foundation
import HTTPTypes

@testable import App


@Suite("Room Tests")
struct RoomTests {

    struct ConstantGenerator: Room.CodeGenerator {
        var limit: Int { 5 }
        let code: Room.Code
        
        init(code: Room.Code) {
            self.code = code
        }

        func next() -> Room.Code {
            return code
        }
        
    }
    
    @Test("Generation throws at limit")
    func errorThrownWhenLimitExceeded() async throws {
        let repository = InMemoryRoomRepository(generator: ConstantGenerator(code: "676767"))
        _ = try await repository.addRoom(name: "First")
        await #expect(throws: Room.Error.FailedToGenerateCode.self) {
            try await repository.addRoom(name: "Second")
        }
    }

    @Test("Generation failure has 500 status")
    func generationFailureHas500Status() async throws {
        let error = Room.Error.FailedToGenerateCode()
        #expect(error.status == .internalServerError)
    }

}
