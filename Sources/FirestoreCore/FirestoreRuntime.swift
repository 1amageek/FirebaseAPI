import Foundation

package protocol FirestoreRuntimeIdentifying: AnyObject, Sendable {
    var runtimeDatabase: Database { get }
}

package protocol FirestoreDocumentRuntime: FirestoreRuntimeIdentifying {
    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot
    func setData(_ data: [String: Any], merge: Bool, for reference: DocumentReference) async throws
    func setData(_ data: [String: Any], mergeFields: [String], for reference: DocumentReference) async throws
    func updateData(_ fields: [String: Any], for reference: DocumentReference) async throws
    func deleteDocument(_ reference: DocumentReference) async throws
    func listCollections(in reference: DocumentReference) async throws -> [CollectionReference]
    func listen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error>
}

package protocol FirestoreCollectionRuntime: FirestoreRuntimeIdentifying {
    func listDocuments(in collection: CollectionReference, pageSize: Int, readTime: Timestamp?) async throws -> [DocumentReference]
}

package protocol FirestoreQueryRuntime: FirestoreRuntimeIdentifying {
    func getDocuments(for query: Query) async throws -> QuerySnapshot
    func listen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error>
    func aggregate(_ query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot
    func explain(_ query: Query, options: FirestoreExplainOptions) async throws -> QueryExplainResult
    func explainAggregation(_ query: Query, fields: [AggregateField], options: FirestoreExplainOptions) async throws -> AggregateQueryExplainResult
}

package protocol FirestorePartitionQueryRuntime: FirestoreRuntimeIdentifying {
    func partitionedQueries(for collectionGroup: CollectionGroup, partitionPointCount: Int, pageSize: Int, readTime: Timestamp?) async throws -> [Query]
}

package protocol FirestoreReferenceRuntime:
    FirestoreDocumentRuntime,
    FirestoreCollectionRuntime,
    FirestoreQueryRuntime,
    FirestorePartitionQueryRuntime
{}

package protocol FirestoreCollectionGroupRuntime:
    FirestoreQueryRuntime,
    FirestorePartitionQueryRuntime
{}

package extension FirestoreCollectionRuntime {
    func listDocuments(
        in collection: CollectionReference,
        pageSize: Int = 0,
        readTime: Timestamp? = nil
    ) async throws -> [DocumentReference] {
        throw FirestoreError.invalidOperation("ListDocuments is not supported by this runtime.")
    }
}

package extension FirestorePartitionQueryRuntime {
    func partitionedQueries(
        for collectionGroup: CollectionGroup,
        partitionPointCount: Int,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [Query] {
        throw FirestoreError.invalidOperation("PartitionQuery is not supported by this runtime.")
    }
}
