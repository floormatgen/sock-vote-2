public import VoteHandling
#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

public extension Question.Description {

    var openAPIQuestion: Components.Schemas.Question {
        .init(
            value1: .init(
                prompt: prompt, 
                votingStyle: votingStyle.openAPIVotingStyle, 
                options: options
            ),
            value2: .init(
                id: id.uuidString,
                state: state.openAPIQuestionState
            )
        )
    }

}
