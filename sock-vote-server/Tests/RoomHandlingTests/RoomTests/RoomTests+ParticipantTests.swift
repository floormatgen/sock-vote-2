import Testing
@testable import RoomHandling

import Foundation

extension RoomTests {

    @Suite
    struct ParticipantTests {

        @Test("Timeout function is called for join request")
        func test_timeoutFunctionIsCalledForJoinRequest() async throws {
            let adminToken = UUID().uuidString
            try await confirmation { confirmation in 
                let room = try createRoom(
                    adminToken: adminToken, 
                    joinRequestTimeoutFunction: { _ in 
                        confirmation.confirm()
                        try unsafe withUnsafeCurrentTask { task in
                            let task = unsafe try #require(task)
                            #expect(unsafe !task.isCancelled)
                        }
                        try await Task.sleep(for: .milliseconds(10))
                    }
                )
                async let joinResult = Self.joinRequest(on: room)
                try await Task.sleep(for: .milliseconds(5))
                let (participantToken, _) = try #require(await room.joinRequests.first {
                    $0.value.name == Self.defaultParticipantName &&
                    $0.value.fields == Self.defaultFields
                })
                let joinRequestResult = await room.handleJoinRequest(true, forToken: participantToken)
                #expect(joinRequestResult == .success)
                guard case .success = try await joinResult else {
                    Issue.record("Request not accepted (result: \(try await joinResult))")
                    return
                }
            }
        }

        @Test("Request reject on timeout expiry")
        func test_requestRejectedOnTimeoutExpiry() async throws {
            try await confirmation { confirmation in
                let room = try createRoom(
                    joinRequestTimeoutFunction: { _ in
                        confirmation.confirm()
                    }
                )
                let joinResult = try await Self.joinRequest(on: room)
                guard case .timeout = joinResult else {
                    Issue.record("Request did not timeout (result: \(joinResult))")
                    return
                }
            }
        }

        static var defaultParticipantName: String {
            "Participant"
        }

        static var defaultFields: [String : String] {
            Dictionary(uniqueKeysWithValues: RoomTests.defaultFields.map { 
                ($0, "\($0)")
            })
        }

        static func joinRequest(
            on room: some RoomProtocol,
            name: String = defaultParticipantName,
            fields: [String : String] = defaultFields
        ) async throws -> JoinResult {
            try await room.requestJoinRoom(
                name: name, 
                fields: fields
            )
        }

    }

}
