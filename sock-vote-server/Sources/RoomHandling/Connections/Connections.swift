import Foundation
import NIOCore

public enum Connections {

    static let encoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    static let decoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    static let allocator = ByteBufferAllocator()

}
