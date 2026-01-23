import Foundation

enum Utilities {

    static func parseTimestamp(_ timestamp: String) throws -> Date {
        let formatStyle = Date.ISO8601FormatStyle()
        let date = try formatStyle.parse(timestamp)
        return date
    }

    actor ActorBox<T> {
        var value: T

        init(value: T) {
            self.value = value
        }

        func setValue(_ value: T) {
            self.value = value
        }

    }
    
}