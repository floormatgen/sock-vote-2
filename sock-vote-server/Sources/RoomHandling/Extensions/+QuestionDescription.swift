import VoteHandling

public extension Question.Description {

    var openAPIQuestion: Components.Schemas.Question {
        .init(
            prompt: prompt, 
            votingStyle: votingStyle.openAPIVotingStyle, 
            options: options
        )
    }

}
