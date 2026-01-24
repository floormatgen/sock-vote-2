import Testing
@testable import SockVoteServer

struct MockOptions: OptionsProvider {
    var hostname: String = "127.0.0.1"
    var port: Int = 8080
}