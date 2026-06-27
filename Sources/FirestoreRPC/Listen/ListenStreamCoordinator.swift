import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestoreRuntimeConfig

package struct ListenStreamCoordinator<State: Sendable, Snapshot: Sendable>: Sendable {
    package typealias ResponseStream = AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error>
    package typealias OpenStream = @Sendable (Google_Firestore_V1_Target) async throws -> ResponseStream
    package typealias StateFactory = @Sendable (Int32) -> State
    package typealias ResponseReducer = @Sendable (inout State, Google_Firestore_V1_ListenResponse) throws -> Snapshot?
    package typealias ResumeTokenProvider = @Sendable (State) -> Data?

    private let targetTemplate: Google_Firestore_V1_Target
    private let maxRetryAttempts: Int
    private let retryStrategy: FirestoreRetryStrategy
    private let nextTargetID: @Sendable () -> Int32
    private let makeState: StateFactory
    private let reduceResponse: ResponseReducer
    private let resumeToken: ResumeTokenProvider
    private let openStream: OpenStream

    package init(
        targetTemplate: Google_Firestore_V1_Target,
        maxRetryAttempts: Int,
        retryStrategy: FirestoreRetryStrategy,
        nextTargetID: @escaping @Sendable () -> Int32,
        makeState: @escaping StateFactory,
        reduceResponse: @escaping ResponseReducer,
        resumeToken: @escaping ResumeTokenProvider,
        openStream: @escaping OpenStream
    ) {
        self.targetTemplate = targetTemplate
        self.maxRetryAttempts = maxRetryAttempts
        self.retryStrategy = retryStrategy
        self.nextTargetID = nextTargetID
        self.makeState = makeState
        self.reduceResponse = reduceResponse
        self.resumeToken = resumeToken
        self.openStream = openStream
    }

    package func makeStream() -> AsyncThrowingStream<Snapshot, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                await run(continuation: continuation)
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func run(continuation: AsyncThrowingStream<Snapshot, Error>.Continuation) async {
        var targetID = nextTargetID()
        var state = makeState(targetID)
        var lastResumeToken: Data?
        var resyncAttempts = 0
        var reconnectAttempts = 0

        while !Task.isCancelled {
            var target = targetTemplate
            target.targetID = targetID
            if let lastResumeToken, !lastResumeToken.isEmpty {
                target.resumeToken = lastResumeToken
            }

            do {
                let responseStream = try await openStream(target)
                for try await response in responseStream {
                    let snapshot = try reduceResponse(&state, response)
                    lastResumeToken = resumeToken(state)
                    reconnectAttempts = 0
                    if let snapshot {
                        resyncAttempts = 0
                        continuation.yield(snapshot)
                    }
                }
                guard !Task.isCancelled else {
                    continuation.finish()
                    return
                }

                let closedError = FirestoreError.rpcError(
                    FirestoreRemoteError(
                        code: .unavailable,
                        message: "Listen stream closed before the consumer stopped listening."
                    )
                )
                guard let delay = reconnectDelay(after: closedError, attempt: reconnectAttempts + 1) else {
                    continuation.finish(throwing: closedError)
                    return
                }
                reconnectAttempts += 1
                guard await sleep(for: delay) else {
                    continuation.finish()
                    return
                }
            } catch is ListenResyncRequired {
                lastResumeToken = nil
                guard resyncAttempts < maxRetryAttempts else {
                    continuation.finish(
                        throwing: FirestoreError.invalidQuery(
                            "Listen stream existence filter mismatch could not be resynchronized after \(maxRetryAttempts) attempts."
                        )
                    )
                    return
                }
                resyncAttempts += 1
                targetID = nextTargetID()
                state = makeState(targetID)
            } catch let error as FirestoreError where error.isRetryableRemoteError {
                guard let delay = reconnectDelay(after: error, attempt: reconnectAttempts + 1) else {
                    continuation.finish(throwing: error)
                    return
                }
                reconnectAttempts += 1
                guard await sleep(for: delay) else {
                    continuation.finish()
                    return
                }
            } catch {
                continuation.finish(throwing: error)
                return
            }
        }

        continuation.finish()
    }

    private func reconnectDelay(after error: FirestoreError, attempt: Int) -> Duration? {
        guard error.isRetryableRemoteError,
              attempt <= maxRetryAttempts
        else {
            return nil
        }
        return retryStrategy.delay(forAttempt: attempt)
    }

    private func sleep(for delay: Duration) async -> Bool {
        do {
            try await Task.sleep(for: delay)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
