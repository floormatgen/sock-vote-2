import Testing
@testable import VoteHandling

@Suite
struct VoteCalculationTests {

    static var defaultOptions: Set<String> {[
        "foo", "bar", "baz"
    ]}

    static var defaultOptionsArray: [String] {
        .init(defaultOptions)
    }

}
