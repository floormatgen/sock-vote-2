import Foundation
import Hummingbird

protocol RoomProtocol: Sendable {
    // associatedtype Participant: ParticipantProtocol

    var name: String { get }
    var code: RoomCode { get }



}