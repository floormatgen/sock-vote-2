public extension Components.Schemas.Question {

    var prompt: String {
        value1.prompt
    }

    var votingStyle: Components.Schemas.VotingStyle? {
        value1.votingStyle
    }

    var options: [String] {
        value1.options
    }

    var id: String {
        value2.id
    }

}
