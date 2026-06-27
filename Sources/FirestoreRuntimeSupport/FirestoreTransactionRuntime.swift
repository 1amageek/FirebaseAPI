import Foundation
import FirestoreCore

package protocol FirestoreTransactionRuntime: AnyObject, Sendable {
    func beginTransactionID(readOnly: Bool, readTime: Timestamp?, retryTransactionID: Data?) async throws -> Data
    func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?) async throws -> [DocumentSnapshot]
    func runQuery(query: Query, transactionID: Data?) async throws -> QuerySnapshot
    func commitWrites(_ writes: [WriteData], transactionID: Data?) async throws -> Bool
    func rollbackTransactionID(transactionID: Data) async throws
}
