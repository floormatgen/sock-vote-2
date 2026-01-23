import Foundation

enum Utilities {

    static func parseTimestamp(_ timestamp: String) throws -> Date {
        let formatStyle = Date.ISO8601FormatStyle()
        let date = try formatStyle.parse(timestamp)
        return date
    }

}