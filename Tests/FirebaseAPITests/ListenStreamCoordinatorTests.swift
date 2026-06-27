import Foundation
import FirestoreProtobuf
import FirestoreRPC
import Testing
@testable import FirestoreAPI

@Suite("Listen Stream Coordinator Tests")
struct ListenStreamCoordinatorTests {
    @Test("ListenStreamCoordinator reconnects retryable stream with resume token")
    func testReconnectsRetryableStreamWithResumeToken() async throws {
        let recorder = ListenTargetRecorder()
        let targetIDGenerator = ListenTargetIDGenerator()
        let token = Data([7, 8, 9])
        let retryableError = FirestoreError.rpcError(
            FirestoreRemoteError(code: .unavailable, message: "temporary disconnect")
        )

        let coordinator = ListenStreamCoordinator<TestListenState, Int>(
            targetTemplate: Self.makeTargetTemplate(),
            maxRetryAttempts: 2,
            retryStrategy: .custom { _ in .nanoseconds(0) },
            nextTargetID: {
                targetIDGenerator.next()
            },
            makeState: { _ in
                TestListenState()
            },
            reduceResponse: { state, response in
                try Self.reduce(state: &state, response: response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                let call = await recorder.record(target)
                if call == 1 {
                    return Self.makeStream(
                        responses: [Self.resumeTokenResponse(token, targetID: target.targetID)],
                        error: retryableError
                    )
                }
                return Self.makeOpenStream(responses: [Self.outputResponse(targetID: target.targetID)])
            }
        )

        let outputs = try await Self.collectFirst(coordinator.makeStream())
        let targets = await recorder.snapshot()

        #expect(outputs == [1])
        #expect(targets.count == 2)
        #expect(targets[0].targetID == targets[1].targetID)
        #expect(targets[0].resumeToken.isEmpty)
        #expect(targets[1].resumeToken == token)
    }

    @Test("ListenStreamCoordinator clears resume token for full resync")
    func testClearsResumeTokenForFullResync() async throws {
        let recorder = ListenTargetRecorder()
        let targetIDGenerator = ListenTargetIDGenerator()
        let token = Data([1, 2, 3])

        let coordinator = ListenStreamCoordinator<TestListenState, Int>(
            targetTemplate: Self.makeTargetTemplate(),
            maxRetryAttempts: 2,
            retryStrategy: .custom { _ in .nanoseconds(0) },
            nextTargetID: {
                targetIDGenerator.next()
            },
            makeState: { _ in
                TestListenState()
            },
            reduceResponse: { state, response in
                try Self.reduce(state: &state, response: response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                let call = await recorder.record(target)
                if call == 1 {
                    return Self.makeStream(
                        responses: [
                            Self.resumeTokenResponse(token, targetID: target.targetID),
                            Self.existenceFilterResponse(count: 0, targetID: target.targetID)
                        ]
                    )
                }
                return Self.makeOpenStream(responses: [Self.outputResponse(targetID: target.targetID)])
            }
        )

        let outputs = try await Self.collectFirst(coordinator.makeStream())
        let targets = await recorder.snapshot()

        #expect(outputs == [1])
        #expect(targets.count == 2)
        #expect(targets[0].targetID != targets[1].targetID)
        #expect(targets[0].resumeToken.isEmpty)
        #expect(targets[1].resumeToken.isEmpty)
    }

    @Test("ListenStreamCoordinator reconnects cleanly closed stream")
    func testReconnectsCleanlyClosedStream() async throws {
        let recorder = ListenTargetRecorder()
        let coordinator = ListenStreamCoordinator<TestListenState, Int>(
            targetTemplate: Self.makeTargetTemplate(),
            maxRetryAttempts: 1,
            retryStrategy: .custom { _ in .nanoseconds(0) },
            nextTargetID: {
                1
            },
            makeState: { _ in
                TestListenState()
            },
            reduceResponse: { state, response in
                try Self.reduce(state: &state, response: response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                let call = await recorder.record(target)
                if call == 1 {
                    return Self.makeStream(responses: [])
                }
                return Self.makeOpenStream(responses: [Self.outputResponse(targetID: target.targetID)])
            }
        )

        let outputs = try await Self.collectFirst(coordinator.makeStream())
        let targets = await recorder.snapshot()

        #expect(outputs == [1])
        #expect(targets.count == 2)
        #expect(targets[0].targetID == targets[1].targetID)
    }

    @Test("ListenStreamCoordinator resets reconnect attempts after response activity")
    func testResetsReconnectAttemptsAfterResponseActivity() async throws {
        let recorder = ListenTargetRecorder()
        let token = Data([4, 5, 6])
        let retryableError = FirestoreError.rpcError(
            FirestoreRemoteError(code: .unavailable, message: "temporary disconnect")
        )

        let coordinator = ListenStreamCoordinator<TestListenState, Int>(
            targetTemplate: Self.makeTargetTemplate(),
            maxRetryAttempts: 1,
            retryStrategy: .custom { _ in .nanoseconds(0) },
            nextTargetID: {
                1
            },
            makeState: { _ in
                TestListenState()
            },
            reduceResponse: { state, response in
                try Self.reduce(state: &state, response: response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                let call = await recorder.record(target)
                if call == 1 {
                    return Self.makeStream(responses: [], error: retryableError)
                }
                if call == 2 {
                    return Self.makeStream(
                        responses: [Self.resumeTokenResponse(token, targetID: target.targetID)],
                        error: retryableError
                    )
                }
                return Self.makeOpenStream(responses: [Self.outputResponse(targetID: target.targetID)])
            }
        )

        let outputs = try await Self.collectFirst(coordinator.makeStream())
        let targets = await recorder.snapshot()

        #expect(outputs == [1])
        #expect(targets.count == 3)
        #expect(targets[0].targetID == targets[1].targetID)
        #expect(targets[1].targetID == targets[2].targetID)
        #expect(targets[2].resumeToken == token)
    }

    @Test("ListenStreamCoordinator cancels open response stream when consumer stops")
    func testCancelsOpenResponseStreamWhenConsumerStops() async throws {
        let terminationRecorder = StreamTerminationRecorder()
        let coordinator = ListenStreamCoordinator<TestListenState, Int>(
            targetTemplate: Self.makeTargetTemplate(),
            maxRetryAttempts: 2,
            retryStrategy: .custom { _ in .nanoseconds(0) },
            nextTargetID: {
                1
            },
            makeState: { _ in
                TestListenState()
            },
            reduceResponse: { state, response in
                try Self.reduce(state: &state, response: response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                AsyncThrowingStream { continuation in
                    continuation.yield(Self.outputResponse(targetID: target.targetID))
                    continuation.onTermination = { _ in
                        Task {
                            await terminationRecorder.recordTermination()
                        }
                    }
                }
            }
        )

        let outputs = try await Self.collectFirst(coordinator.makeStream())
        let didTerminate = await Self.waitUntil {
            await terminationRecorder.didTerminate()
        }

        #expect(outputs == [1])
        #expect(didTerminate)
    }

    private static func collect(
        _ stream: AsyncThrowingStream<Int, Error>
    ) async throws -> [Int] {
        var outputs: [Int] = []
        for try await output in stream {
            outputs.append(output)
        }
        return outputs
    }

    private static func collectFirst(
        _ stream: AsyncThrowingStream<Int, Error>
    ) async throws -> [Int] {
        var outputs: [Int] = []
        for try await output in stream {
            outputs.append(output)
            break
        }
        return outputs
    }

    private static func waitUntil(
        _ condition: @escaping @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<20 {
            if await condition() {
                return true
            }
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                return false
            }
        }
        return false
    }

    private static func reduce(
        state: inout TestListenState,
        response: Google_Firestore_V1_ListenResponse
    ) throws -> Int? {
        switch response.responseType {
        case .targetChange(let targetChange):
            if !targetChange.resumeToken.isEmpty {
                state.resumeToken = targetChange.resumeToken
            }
            return nil

        case .filter(let filter):
            throw ListenResyncRequired(
                targetID: filter.targetID,
                expectedCount: 1,
                actualCount: Int(filter.count)
            )

        case .documentChange:
            return 1

        case .documentDelete,
             .documentRemove,
             .none:
            return nil
        }
    }

    private static func makeTargetTemplate() -> Google_Firestore_V1_Target {
        Google_Firestore_V1_Target.with {
            $0.documents = Google_Firestore_V1_Target.DocumentsTarget.with {
                $0.documents = ["projects/test/databases/(default)/documents/users/user1"]
            }
        }
    }

    private static func makeStream(
        responses: [Google_Firestore_V1_ListenResponse],
        error: Error? = nil
    ) -> AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error> {
        AsyncThrowingStream { continuation in
            for response in responses {
                continuation.yield(response)
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }

    private static func makeOpenStream(
        responses: [Google_Firestore_V1_ListenResponse]
    ) -> AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error> {
        AsyncThrowingStream { continuation in
            for response in responses {
                continuation.yield(response)
            }
        }
    }

    private static func resumeTokenResponse(
        _ token: Data,
        targetID: Int32
    ) -> Google_Firestore_V1_ListenResponse {
        Google_Firestore_V1_ListenResponse.with {
            $0.targetChange = Google_Firestore_V1_TargetChange.with {
                $0.targetChangeType = .noChange
                $0.targetIds = [targetID]
                $0.resumeToken = token
            }
        }
    }

    private static func existenceFilterResponse(
        count: Int32,
        targetID: Int32
    ) -> Google_Firestore_V1_ListenResponse {
        Google_Firestore_V1_ListenResponse.with {
            $0.filter = Google_Firestore_V1_ExistenceFilter.with {
                $0.count = count
                $0.targetID = targetID
            }
        }
    }

    private static func outputResponse(targetID: Int32) -> Google_Firestore_V1_ListenResponse {
        Google_Firestore_V1_ListenResponse.with {
            $0.documentChange = Google_Firestore_V1_DocumentChange.with {
                $0.targetIds = [targetID]
                $0.document = Google_Firestore_V1_Document.with {
                    $0.name = "projects/test/databases/(default)/documents/users/user1"
                }
            }
        }
    }
}

private struct TestListenState: Sendable {
    var resumeToken: Data?
}

private actor ListenTargetRecorder {
    private var targets: [Google_Firestore_V1_Target] = []

    func record(_ target: Google_Firestore_V1_Target) -> Int {
        targets.append(target)
        return targets.count
    }

    func snapshot() -> [Google_Firestore_V1_Target] {
        targets
    }
}

private actor StreamTerminationRecorder {
    private var terminated = false

    func recordTermination() {
        terminated = true
    }

    func didTerminate() -> Bool {
        terminated
    }
}
