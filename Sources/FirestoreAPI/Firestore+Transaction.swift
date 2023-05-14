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
        _ transactionFunction: @escaping ((Transaction) async throws -> T?),
        options: TransactionOptions = TransactionOptions()
    ) async throws -> T? {
        let transaction = Transaction(firestore: self, options: options)
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
                // If an error occurs, roll back the transaction.
                try await transaction.rollback()

                // If we've hit the maximum number of attempts, rethrow the error.
                do {
                    try await transaction.backoff.backoffAndWait()
                } catch {
                    // If we've hit the maximum number of attempts, rethrow the error.
                    throw FirestoreError.transactionFailed(error: error)
                }
            }
        }
        return nil
    }
}
