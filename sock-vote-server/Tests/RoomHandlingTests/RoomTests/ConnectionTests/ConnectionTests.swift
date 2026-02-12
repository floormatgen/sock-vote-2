import Testing
@testable import RoomHandling

extension RoomTests {

    @Suite
    struct ConnectionTests {

        struct MockParticipantConnection: Connections.ParticipantConnection {
            var sendQuestionUpdatedHandler: (@Sendable (_ description: Connections.QuestionDescription) async throws -> Void)?
            var sendQuestionDeletedHandler: (@Sendable () async throws -> Void)?
            var removeConnectionHandler: (@Sendable () -> Void)?

            func sendQuestionUpdated(with description: Connections.QuestionDescription) async throws {
                try await sendQuestionUpdatedHandler?(description)
            }

            func sendQuestionDeleted() async throws {
                try await sendQuestionDeletedHandler?()
            }

            func removeConnection() {
                removeConnectionHandler?()
            }

        }

    }

}
