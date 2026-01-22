import Testing
@testable import RoomHandling

@Suite
struct RoomHandlerTests {
    let roomHandler: DefaultRoomHandler

    init() async throws {
        self.roomHandler = DefaultRoomHandler()
    }

    static var roomNames: [String] {[
        "UTS PCSoc Annual General Meeting",
        "BLÅHAJ committe meeting",
    ]}

    @Test("Room created with correct info", arguments: Self.roomNames)
    func test_roomCreatedWithCorrectInfo(_ name: String) async throws {
        let createOutput = try await roomHandler.postRoomCreate(.init(body: .json(.init(name: name))))
        let createName = try createOutput.ok.body.json.name
        let createCode = try createOutput.ok.body.json.code
        #expect(createName == name)
        let infoOutput = try await roomHandler.getRoomInfoCode(.init(path: .init(code: createCode)))
        let infoName = try infoOutput.ok.body.json.name
        let infoCode = try infoOutput.ok.body.json.code
        #expect(createName == infoName)
        #expect(createCode == infoCode)
    }

}