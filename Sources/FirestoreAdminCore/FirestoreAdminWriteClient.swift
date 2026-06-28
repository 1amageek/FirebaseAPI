import Foundation

public protocol FirestoreAdminWriteClient: Sendable {
    func batch() -> FirestoreAdminWriteBatch
    func bulkWriter() -> FirestoreAdminBulkWriter
}
