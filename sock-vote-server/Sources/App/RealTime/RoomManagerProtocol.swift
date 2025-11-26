import Foundation
import Hummingbird

protocol RoomManagerProtocol: RoomRepository {

    func roomDidBecomeAlive(code: RoomCode) async throws
    func roomDidBecomeInactive(code: RoomCode) async throws

}