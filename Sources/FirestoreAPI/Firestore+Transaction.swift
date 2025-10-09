//
//  Firestore+Transaction.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation


extension Firestore {

    /**
      Run a transaction on the Firestore database.

      A transaction is a way to perform multiple operations on the database in a single atomic unit. This is useful for operations that need to be performed atomically, such as updating multiple documents or deleting a document and creating a new one in its place.

      - Parameter transactionFunction: A closure that takes a `Transaction` instance as its argument and returns a value. The `Transaction` instance can be used to read and write data from the database.
      - Returns: The value returned by the `transactionFunction` closure.
      - Throws: A `FirestoreError` if the transaction fails.
      */
    public func runTransaction<T>(
        _ transactionFunction: @escaping ((Transaction<Transport>) async throws -> T?),
        options: TransactionOptions = TransactionOptions()
    ) async throws -> T? {
        let transaction = Transaction(firestore: self, options: options)
        var lastError: Error?

        while transaction.backoff.shouldRetry {
            do {
                // Begin the transaction.
                try await transaction.begin(readOnly: options.readOnly, readTime: options.readTime)

                // Call the transaction function.
                let result: T? = try await transactionFunction(transaction)

                // Commit the transaction.
                try await transaction.commit()

                return result
            } catch {
                // Save the original error
                lastError = error

                // Check if error is an aborted transaction error
                // If so, Firestore has already rolled back the transaction automatically
                let isAbortedError: Bool = {
                    if case FirestoreError.rpcError(let rpcError) = error {
                        return rpcError.code == .aborted
                    }
                    return false
                }()

                // Only rollback if the transaction wasn't aborted by Firestore
                // (aborted transactions are automatically rolled back by Firestore)
                if !isAbortedError {
                    do {
                        try await transaction.rollback()
                    } catch {
                        // Continue to retry even if rollback fails
                    }
                }

                // Try to backoff and retry
                do {
                    try await transaction.backoff.backoffAndWait()
                } catch {
                    // Maximum retry attempts exceeded - throw with original error
                    throw FirestoreError.transactionFailed(error: lastError ?? error)
                }
            }
        }

        // This point should not be reached, but throw error if it does
        throw FirestoreError.transactionFailed(
            error: lastError ?? TransactionError.maxRetriesExceeded(
                attempts: transaction.backoff.retryCount,
                lastError: NSError(domain: "FirestoreTransaction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction exceeded maximum retries"])
            )
        )
    }
}
