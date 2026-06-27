import Foundation
import FirestoreCore
import FirestoreRuntimeSupport

extension FirestoreAdmin {
    public func runTransaction<T>(
        _ transactionFunction: @escaping (FirestoreAdminTransaction) async throws -> T?,
        options: TransactionOptions = TransactionOptions()
    ) async throws -> T? {
        let transaction = FirestoreAdminTransaction(
            database: database,
            runtime: transactionRuntime,
            options: options
        )
        var lastError: Error?
        var retryTransactionID: Data?

        while transaction.backoff.shouldRetry {
            do {
                try await transaction.begin(
                    readOnly: options.readOnly,
                    readTime: options.readTime,
                    retryTransactionID: retryTransactionID
                )
                let result = try await transactionFunction(transaction)
                if options.readOnly {
                    try transaction.completeReadOnly()
                } else {
                    try await transaction.commit()
                }
                return result
            } catch {
                let originalError = error
                lastError = originalError

                if isAbortedTransaction(originalError) {
                    retryTransactionID = transaction.transactionID
                } else if transaction.hasTransactionID {
                    do {
                        try await transaction.rollback()
                    } catch {
                        throw FirestoreError.transactionFailed(
                            error: TransactionError.rollbackFailed(original: originalError, rollback: error)
                        )
                    }
                }

                guard shouldRetryTransaction(originalError) else {
                    throw publicTransactionError(originalError)
                }

                do {
                    try await transaction.backoff.waitBeforeNextAttempt()
                } catch {
                    throw FirestoreError.transactionFailed(error: lastError ?? error)
                }
            }
        }

        throw FirestoreError.transactionFailed(
            error: lastError ?? TransactionError.maxRetriesExceeded(
                attempts: transaction.backoff.retryCount,
                lastError: NSError(
                    domain: "FirestoreAdminTransaction",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Transaction exceeded maximum retries"]
                )
            )
        )
    }

    private func isAbortedTransaction(_ error: Error) -> Bool {
        if case FirestoreError.rpcError(let error) = error {
            return error.code == .aborted
        }
        return false
    }

    private func shouldRetryTransaction(_ error: Error) -> Bool {
        if case FirestoreError.rpcError(let error) = error {
            return error.code == .aborted
        }
        return false
    }

    private func publicTransactionError(_ error: Error) -> Error {
        if error is TransactionError {
            return FirestoreError.transactionFailed(error: error)
        }
        return error
    }
}
