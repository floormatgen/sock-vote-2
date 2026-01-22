package final actor Room {
    nonisolated let name: String
    nonisolated let code: String
    nonisolated private let adminToken: String

    init(name: String, code: String, adminToken: String) {
        self.name = name
        self.code = code
        self.adminToken = adminToken
    }
}