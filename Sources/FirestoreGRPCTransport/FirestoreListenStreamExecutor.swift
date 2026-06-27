import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreProtobuf
import GRPCCore

package struct FirestoreListenStreamExecutor: Sendable {
    package typealias ListenResponseHandler = @Sendable (StreamingClientResponse<Google_Firestore_V1_ListenResponse>) async throws -> Void
    package typealias OpenListen = @Sendable (
        StreamingClientRequest<Google_Firestore_V1_ListenRequest>,
        @escaping ListenResponseHandler
    ) async throws -> Void

    private let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeResponseStream(
        target: Google_Firestore_V1_Target,
        metadata: Metadata,
        openListen: @escaping OpenListen
    ) async -> AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error> {
        let requestController = ListenRequestStreamController(database: database, target: target)
        let requestMessages = await requestController.makeRequestStream()

        return AsyncThrowingStream { continuation in
            Task {
                await requestController.openTarget()
            }

            Task {
                do {
                    let request = StreamingClientRequest<Google_Firestore_V1_ListenRequest>(
                        metadata: metadata,
                        producer: { writer in
                            for await requestMessage in requestMessages {
                                try await writer.write(requestMessage)
                            }
                        }
                    )

                    try await openListen(request) { response in
                        for try await message in response.messages {
                            continuation.yield(message)
                        }
                    }
                    continuation.finish()
                } catch let error as RPCError {
                    continuation.finish(throwing: FirestoreError.fromRPCError(error))
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                Task {
                    await requestController.closeTarget()
                }
            }
        }
    }
}
