import Foundation
import Hummingbird

actor InMemoryRoom: RoomProtocol {
    let name: String
    let code: RoomCode

    init(name: String, code: RoomCode) {
        self.name = name
        self.code = code
    }

}