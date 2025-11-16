import Testing
import Foundation
import HTTPTypes

@testable import App


@Suite("Room Tests")
struct RoomTests {

    struct ConstantGenerator: RoomCodeGenerator {
        var limit: Int { 5 }
        let code: RoomCode
        
        init(code: RoomCode) {
            self.code = code
        }

        func next() -> RoomCode {
            return code
        }
        
    }
    
    @Test("Generation throws at limit")
    func errorThrownWhenLimitExceeded() async throws {
        let repository = InMemoryRoomRepository(generator: ConstantGenerator(code: "676767"))
        _ = try await repository.addRoom(name: "First")
        let error = try await #require(throws: RoomCodeError.self) {
            try await repository.addRoom(name: "Second")
        }
        #expect(error == .failedToGenerateCode)
    }

    @Test("Generation failure has 500 status")
    func generationFailureHas500Status() async throws {
        let error = RoomCodeError.failedToGenerateCode
        #expect(error.status == .internalServerError)
    }

}
