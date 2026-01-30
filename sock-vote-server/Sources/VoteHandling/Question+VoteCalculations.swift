extension Question {

    public enum Result: Equatable {
        case noVotes
        case tie(winners: [String])
        case hasWinner(String)

        internal init(from modeResult: [String : some Comparable].ModeResult?) {
            switch modeResult {
                case .single(let winner):
                    self = .hasWinner(winner)
                case .multiple(let winners):
                    self = .tie(winners: winners)
                case .none:
                    self = .noVotes
            }
        }

    }

    /// Generates a result using the plurality method
    /// 
    /// The option that has the most votes will win. If multiple options have the same amount of votes, they will ``Qestion/Result/tie``.
    /// 
    /// - Throws:
    ///     ``Question/Error/invalidVote`` when an invalid vote is detected.
    public static func pluralityResult(
        using votes: some Collection<PluralityVote>,
        options: borrowing Set<String>
    ) throws -> Result {
        var counts = [String : Int](minimumCapacity: options.count)
        for vote in votes {
            guard vote.validate(usingOptions: options) else {
                throw Error.invalidVote
            }
            counts[vote.selection, default: 0] += 1
        }
        return .init(from: counts.mode())
    }

    /// Generates a result using the instant runoff method
    /// 
    /// > Sources:
    /// > Implementation is hevily inspired by [electowiki.org](https://electowiki.org/wiki/Instant-runoff_voting).
    /// 
    /// - Throws:
    ///     ``Question/Error/invalidVote`` when an invalid vote is detected.
    /// 
    /// ### Handling Ties
    /// 
    /// 1. If multiple candidates have the same amount of first preference votes, **but not the most**, then they are **all eliminated at the same time**.
    /// 2. If **all candidates** have the same amount of first preference votes, no one is eliminated and second preference votes are also considered.
    /// 3. If there are still multiple candidates, the vote ends in a **tie** between the remaining candidates.
    /// 
    public static func preferentialResult(
        using votes: some Collection<PreferentialVote>,
        options: borrowing Set<String>
    ) throws -> Result {
        guard !votes.isEmpty else { return .noVotes }

        // Setup
        typealias Counts = [String : Int]
        let winThreshold = (votes.count / 2) + 1
        let requiredCount = options.count
        var counts = Counts(minimumCapacity: requiredCount)
        var countingFirstNVotes = 1
        options.forEach { counts[$0] = 0 }

        // Validation
        try votes.forEach {
            guard $0.validate(usingOptions: options) else {
                throw Error.invalidVote
            }
        }

        // Loop
        while true {
            // Reset counts to 0
            counts.keys.forEach { key in
                counts[key] = 0
            }
            
            var minValue = Int.max
            var maxValue = Int.min

            for vote in votes {
                var remaining = countingFirstNVotes
                for selection in vote.selectionOrder where remaining > 0 {
                    guard counts.keys.contains(selection) else { continue }
                    counts[selection]! += 1
                    remaining -= 1
                }
            }

            // debugPrint(countingFirstNVotes)
            // debugPrint(counts)

            for (k, v) in counts {
                // If a candidate has more than 50% of the vote, end early.
                guard v < winThreshold || countingFirstNVotes > 1 else { return .hasWinner(k) }
                minValue = min(minValue, v)
                maxValue = max(maxValue, v)
            }
            assert(minValue <= maxValue)

            if minValue < maxValue {
                counts.removeValues { $0 == minValue }
                countingFirstNVotes = 1
            } else /* if minValue == maxValue */ {
                guard countingFirstNVotes < options.count else { return .tie(winners: options.map(\.self)) }
                countingFirstNVotes += 1
            }

        }

    }

}
