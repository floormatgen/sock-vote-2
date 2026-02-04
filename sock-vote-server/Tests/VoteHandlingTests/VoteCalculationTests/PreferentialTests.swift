import Testing
@testable import VoteHandling

extension VoteCalculationTests {

    @Suite
    struct PreferentialTests {

        @Test("No result with no votes")
        func test_hasNoResultWithNoVotes() throws {
            let result = try Question.preferentialResult(using: EmptyCollection(), options: defaultOptions)
            #expect(result == .noVotes)
        }

        @Test("Throws on invalid vote", arguments: [
            .init(
                "Too few options", 
                votes: [
                    [0, 1],
                    [1, 2, 0],
                ]),
            .init(
                "Too many options",
                votes: [
                    [0, 1, 2],
                    [1, 2, 0, 0],
                ]),
            .init(
                "Duplicate options",
                votes: [
                    [0, 0, 2],
                    [0, 2, 1],
                ]),
            .init(
                "Invalid options",
                votes: [
                    [0, 2, 3],
                    [-1, 0, 1],
                ]),
        ] as [TestArgument])
        func test_throwsOnInvalidVote(_ argument: TestArgument) throws {
            try #require(throws: Question.Error.invalidVote) {
                _ = try Question.preferentialResult(using: argument.votes, options: argument.options)
            }
        }

        @Test("Can find concrete winner", arguments: [
            .init(
                "No ties",
                votes: [
                    [0, 1, 2],
                    [0, 2, 1],
                    [1, 0, 2],
                ], expectedResult: 0),
            .init(
                "First preference tie",
                votes: [
                    [0, 1, 2],
                    [1, 0, 2],
                    [2, 0, 1],
                ], expectedResult: 0),
            .init(
                "Second preference tie", optionsCount: 5,
                votes: [
                    [0, 1, 2, 3, 4],
                    [1, 2, 3, 4, 0],
                    [2, 3, 1, 0, 4],
                    [3, 4, 1, 0, 2],
                    [4, 0, 1, 2, 3],
                ], expectedResult: 1)
        ] as [TestArgument])
        func test_canFindConcreteWinner(_ testArgument: TestArgument) throws {
            let result = try Question.preferentialResult(using: testArgument.votes, options: testArgument.options)
            try testArgument.checkResult(result)
        }

        @Test("Can find full tie", arguments: [
            .init(
                "3 Options",
                votes: [
                    [0, 1, 2],
                    [1, 2, 0],
                    [2, 0, 1],
                ],
                expectedResult: .init(0..<3)),
            .init(
                "Single Option",
                optionsCount: 1,
                votes: repeatElement([0], count: 10).map(\.self),
                expectedResult: 0)
        ] as [TestArgument])
        func test_canFindFullTie(_ testArgument: TestArgument) throws {
            let result = try Question.preferentialResult(using: testArgument.votes, options: testArgument.options)
            try testArgument.checkResult(result)
        }

        // MARK: - Utility

        struct TestArgument: Sendable, CustomTestArgumentEncodable, CustomTestStringConvertible {
            let label: String?
            let options: Set<String>
            let optionsArray: [String]
            let optionsCount: Int
            let votes: [Question.PreferentialVote]
            let expectedResult: [String]

            init(_ label: String? = nil, optionsCount: Int = 3, votes: [[Int]], expectedResult: Int = 0) {
                self.init(label, optionsCount: optionsCount, votes: votes, expectedResult: [expectedResult])
            }

            init(_ label: String? = nil, optionsCount: Int = 3, votes: [[Int]], expectedResult: [Int]) {
                self.label = label
                self.optionsCount = optionsCount
                let optionsArray = Array((0..<optionsCount).map(String.init))
                self.optionsArray = optionsArray
                self.options = Set(optionsArray)
                self.votes = votes.map {
                    .init(
                        selectionOrder: $0.map {
                            if optionsArray.indices.contains($0) {
                                return optionsArray[$0]
                            } else {
                                return "Out of range: \($0)"
                            }
                        })
                }
                self.expectedResult = expectedResult.map { optionsArray[$0] }
            }

            func checkResult(_ result: Question.Result) throws {
                switch result {
                    case .singleWinner(let winner):
                        try #require(expectedResult.count == 1)
                        let expectedWinner = try #require(expectedResult.first)
                        try #require(expectedWinner == winner, 
                            """
                            Incorrect winner, got \(winner) instead of \(expectedWinner).
                            optionsArray: \(self.optionsArray)
                            """
                        )
                    case .tie(let winners):
                        try #require(Set(winners) == options)
                    case .noVotes:
                        try #require(votes.isEmpty)
                }
            }

            enum CodingKeys: String, CodingKey {
                case optionsCount
                case votes
                case expectedResult
            }

            func encodeTestArgument(to encoder: some Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(optionsCount, forKey: .optionsCount)
                try container.encode(votes.map(\.selectionOrder), forKey: .votes)
                try container.encode(expectedResult, forKey: .expectedResult)
            }

            var testDescription: String {
                label ?? String(describing: self)
            }

        }

    }

}
