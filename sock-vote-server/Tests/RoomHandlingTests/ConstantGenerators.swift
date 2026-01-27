import Testing
@testable import RoomHandling

struct ConstantRoomCodeGenerator: RoomCodeGeneratorProtocol {
    let value: String

    init(value: String) {
        self.value = value
    }

    mutating func next() -> String {
        return value
    }

}