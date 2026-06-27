import Foundation
import FirestoreCore
import FirestoreRuntimeConfig
import GRPCCore

struct FirestoreRPCExecutor: Sendable {
    private let retryStrategy: FirestoreRetryStrategy
    private let maxAttempts: Int
    private let maxDuration: TimeInterval

    init(
        retryStrategy: FirestoreRetryStrategy,
        maxAttempts: Int,
        maxDuration: TimeInterval
    ) {
        self.retryStrategy = retryStrategy
        self.maxAttempts = maxAttempts
        self.maxDuration = maxDuration
    }

    func executeWithRetry<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let retryHandler = FirestoreRetryHandler(
            strategy: retryStrategy,
            maxAttempts: maxAttempts,
            maxDuration: maxDuration
        )
        return try await retryHandler.execute(FirestoreRetryableOperation(operation))
    }

    func executeWithoutAutomaticRetry<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        do {
            return try await operation()
        } catch let error as RPCError {
            throw FirestoreError.fromRPCError(error)
        } catch {
            throw error
        }
    }
}
