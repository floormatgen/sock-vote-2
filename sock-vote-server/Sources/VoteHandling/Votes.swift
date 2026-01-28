extension Question {

    public struct PluralityVote {
        public var selection: String

        public func validate(usingOptions options: borrowing Set<String>) -> Bool {
            return options.contains(selection)
        }

    }

    public struct PreferentialVote {
        public var selectionOrder: [String]

        public func validate(usingOptions options: borrowing Set<String>) -> Bool {
            guard selectionOrder.count == options.count else { return false }
            var seen = Set<String>(minimumCapacity: options.count)
            for selection in selectionOrder {
                guard options.contains(selection), !seen.contains(selection) else { return false }
                seen.insert(selection)
            }
            return true
        }

    }

}
