import Foundation
import FirestoreCore

public protocol FirestoreAdminTransactionClient: Sendable {
    func runTransaction<T>(
        _ transactionFunction: @escaping (FirestoreAdminTransaction) async throws -> T?,
        options: TransactionOptions
    ) async throws -> T?
}

public extension FirestoreAdminTransactionClient {
    func runTransaction<T>(
        _ transactionFunction: @escaping (FirestoreAdminTransaction) async throws -> T?
    ) async throws -> T? {
        try await runTransaction(transactionFunction, options: TransactionOptions())
    }
}
