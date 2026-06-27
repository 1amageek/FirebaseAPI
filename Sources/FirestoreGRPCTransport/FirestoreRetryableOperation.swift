import Foundation
import FirestoreCore
import FirestoreRuntimeConfig
import GRPCCore

struct FirestoreRetryableOperation<T>: FirestoreRetryable {
    private let operation: @Sendable () async throws -> T

    init(_ operation: @escaping @Sendable () async throws -> T) {
        self.operation = operation
    }

    func execute() async throws -> T {
        do {
            return try await operation()
        } catch let error as RPCError {
            throw FirestoreError.fromRPCError(error)
        } catch {
            throw error
        }
    }
}
