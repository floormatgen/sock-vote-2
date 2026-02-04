import Testing
@testable import RoomHandling

import VoteHandling

@Suite
struct ExtensionTests {

    @Test("Can round trip question state")
    func test_canRoundTripQuestionState() async throws {
        try await #require(processExitsWith: .success) {
            let states = Components.Schemas.QuestionState.allCases
            for s in states {
                #expect(s == Question.State(s).openAPIQuestionState)
            }
        }
    }

    @Test("Can round trip question result", arguments: [
        .noVotes,
        .singleWinner("foo"),
        .tie(winners: ["bar", "baz"])
    ] as [Question.Result])
    func test_canRoundTripQuestionResult(_ result: Question.Result) throws {
        #expect(result == .init(result.openAPIQuestionResult))
    }

}
