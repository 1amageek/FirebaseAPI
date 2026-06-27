import Foundation

public struct FirestoreBulkWriteOperationResult: Equatable, Sendable {
    public let index: Int
    public let document: DocumentReference
    public let updateTime: Timestamp?
    public let error: FirestoreRemoteError?

    public var succeeded: Bool {
        error == nil
    }

    public init(
        index: Int,
        document: DocumentReference,
        updateTime: Timestamp?,
        error: FirestoreRemoteError?
    ) {
        self.index = index
        self.document = document
        self.updateTime = updateTime
        self.error = error
    }
}
