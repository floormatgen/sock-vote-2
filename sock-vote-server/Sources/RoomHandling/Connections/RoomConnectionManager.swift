import VoteHandling
import ServiceLifecycle
import AsyncAlgorithms
import Logging

extension Room {

    internal final actor ConnectionManager: Service {

        internal enum ParticipantMessage {
            case questionUpdated(question: Connections.Question)
            case questionDeleted
        }

        private let logger: Logger

        private typealias ParticipantStream = AsyncStream<ParticipantMessage>
        private nonisolated let participantMessageStream: ParticipantStream
        private nonisolated let participantMessageContinutaion: ParticipantStream.Continuation

        private var participantConnections: [String : ParticipantConnection]

        internal init(logger: Logger = Logger(label: "ConnectionManager")) {
            let (participantMessageSteam, participantMessageContinutaion) = ParticipantStream.makeStream()
            self.participantMessageStream = participantMessageSteam
            self.participantMessageContinutaion = participantMessageContinutaion

            self.participantConnections = [:]
            self.logger = logger
        }

        internal func registerConnection(
            _ connection: ParticipantConnection, 
            forParticipantToken participantToken: String
        ) throws {
            guard !participantConnections.keys.contains(participantToken) else {
                throw ConnectionManagerError.participantAlreadyConnected(participantToken: participantToken)
            }
            participantConnections[participantToken] = connection
        }

        /// Cleans up the 
        internal nonisolated func cleanup() {
            self.participantMessageContinutaion.finish()
        }

        internal func run() async throws {
            await withTaskCancellationOrGracefulShutdownHandler {
                await withTaskGroup { taskGroup in

                    // Participant Messages
                    taskGroup.addTask {
                        for await message in self.participantMessageStream {
                            await withDiscardingTaskGroup { participantGroup in
                                for (participantToken, connection) in await self.participantConnections {
                                    participantGroup.addTask {
                                        do {
                                            self.logger.trace("Sending question update to participant with token \(participantToken)")
                                            switch message {
                                                case .questionUpdated(let question):
                                                    try await connection.sendQuestionUpdate(with: question)
                                                case .questionDeleted:
                                                    try await connection.sendQuestionRemove()
                                            }
                                        } catch {
                                            self.logger.debug("Failed to send question update to participant with token \(participantToken)")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    await taskGroup.waitForAll()
                }
            } onCancelOrGracefulShutdown: {
                self.cleanup()
            }
        }

    }

}

// MARK: - Errors

internal enum ConnectionManagerError: Swift.Error {
    /// The participant is already registered with the connection manager
    case participantAlreadyConnected(participantToken: String)
}
