extension Question {

    public struct PluralityVote: Sendable {
        public var selection: String

        public init(selection: String) {
            self.selection = selection
        }

        public func validate(usingOptions options: borrowing Set<String>) -> Bool {
            return options.contains(selection)
        }

    }

    public struct PreferentialVote: Sendable {
        public var selectionOrder: [String]

        public init(selectionOrder: [String]) {
            self.selectionOrder = selectionOrder
        }

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
