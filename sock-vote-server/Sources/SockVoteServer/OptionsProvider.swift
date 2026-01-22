import Foundation

protocol OptionsProvider {
    var hostname: String { get }
    var port: Int { get }
}