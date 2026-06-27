import Foundation

enum TransactionError: Error {
    case missingTransactionID
    case rollbackFailed(original: Error, rollback: Error)
    case maxRetriesExceeded(attempts: Int, lastError: Error)
}
