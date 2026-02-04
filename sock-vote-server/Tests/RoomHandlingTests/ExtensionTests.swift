import Testing
@testable import RoomHandling

import VoteHandling

@Suite
struct ExtensionTests {

    @Test("Can round trip state")
    func test_canRoundTripQuestionState() async throws {
        try await #require(processExitsWith: .success) {
            let states = Components.Schemas.QuestionState.allCases
            for s in states {
                #expect(s == Question.State(s).openAPIQuestionState)
            }
        }
    }

}
