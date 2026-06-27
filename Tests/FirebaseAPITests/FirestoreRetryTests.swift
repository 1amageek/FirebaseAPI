import Foundation
import FirestoreCore
import FirestoreRuntimeConfig
import Testing
@testable import FirestoreAPI

@Suite("Firestore Retry Tests")
struct FirestoreRetryTests {
    @Test("Retry handler retries retryable remote errors")
    func testRetryHandlerRetriesRetryableRemoteErrors() async throws {
        let operation = RetryProbeOperation(
            failures: [
                FirestoreError.rpcError(
                    FirestoreRemoteError(code: .unavailable, message: "Service unavailable")
                )
            ],
            successValue: 2
        )
        let handler = FirestoreRetryHandler(
            strategy: .custom { _ in .zero },
            maxAttempts: 3
        )

        let value = try await handler.execute(operation)

        #expect(value == 2)
        #expect(await operation.attemptCount == 2)
    }

    @Test("Retry handler does not retry non-retryable remote errors")
    func testRetryHandlerDoesNotRetryNonRetryableRemoteErrors() async throws {
        let operation = RetryProbeOperation(
            failures: [
                FirestoreError.rpcError(
                    FirestoreRemoteError(code: .permissionDenied, message: "Permission denied")
                )
            ],
            successValue: 2
        )
        let handler = FirestoreRetryHandler(
            strategy: .custom { _ in .zero },
            maxAttempts: 3
        )

        var didThrowPermissionDenied = false
        do {
            _ = try await handler.execute(operation)
        } catch FirestoreError.rpcError(let error) {
            didThrowPermissionDenied = error.code == .permissionDenied
        } catch {
            didThrowPermissionDenied = false
        }

        #expect(didThrowPermissionDenied)
        #expect(await operation.attemptCount == 1)
    }

    @Test("Retry handler stops at max retry attempts")
    func testRetryHandlerStopsAtMaxRetryAttempts() async throws {
        let operation = RetryProbeOperation(
            failures: [
                FirestoreError.rpcError(FirestoreRemoteError(code: .unavailable, message: "1")),
                FirestoreError.rpcError(FirestoreRemoteError(code: .unavailable, message: "2")),
                FirestoreError.rpcError(FirestoreRemoteError(code: .unavailable, message: "3"))
            ],
            successValue: 4
        )
        let handler = FirestoreRetryHandler(
            strategy: .custom { _ in .zero },
            maxAttempts: 3
        )

        var didReachMaxAttempts = false
        do {
            _ = try await handler.execute(operation)
        } catch FirestoreError.maxAttemptsReached {
            didReachMaxAttempts = true
        } catch {
            didReachMaxAttempts = false
        }

        #expect(didReachMaxAttempts)
        #expect(await operation.attemptCount == 3)
    }
}

private actor RetryProbeOperation<Value: Sendable>: FirestoreRetryable {
    private var failures: [Error]
    private let successValue: Value
    private var attempts = 0

    var attemptCount: Int {
        attempts
    }

    init(failures: [Error], successValue: Value) {
        self.failures = failures
        self.successValue = successValue
    }

    func execute() async throws -> Value {
        attempts += 1
        if !failures.isEmpty {
            throw failures.removeFirst()
        }
        return successValue
    }
}
