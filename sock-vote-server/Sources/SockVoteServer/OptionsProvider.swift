import Foundation

@available(*, deprecated)
protocol OptionsProvider {
    var hostname: String { get }
    var port: Int { get }
}