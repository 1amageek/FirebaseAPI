import Foundation
import FirestoreCore
import FirestorePipeline
import FirestoreRPC
import FirestoreRuntimeSupport

extension FirestoreGRPCRuntime: FirestoreRuntime {
    package var runtimeDatabase: Database {
        database
    }

    package func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try validateDatabase(reference.database)
        return try await executeGetDocument(reference)
    }

    package func setData(_ data: [String: Any], merge: Bool, for reference: DocumentReference) async throws {
        try validateDatabase(reference.database)
        try await executeSetData(data, merge: merge, for: reference)
    }

    package func setData(_ data: [String: Any], mergeFields: [String], for reference: DocumentReference) async throws {
        try validateDatabase(reference.database)
        try await executeSetData(data, mergeFields: mergeFields, for: reference)
    }

    package func updateData(_ fields: [String: Any], for reference: DocumentReference) async throws {
        try validateDatabase(reference.database)
        try await executeUpdateData(fields, for: reference)
    }

    package func deleteDocument(_ reference: DocumentReference) async throws {
        try validateDatabase(reference.database)
        try await executeDeleteDocument(reference)
    }

    package func listCollections(in reference: DocumentReference) async throws -> [CollectionReference] {
        try validateDatabase(reference.database)
        return try await executeListCollections(in: reference)
    }

    package func listDocuments(
        in collection: CollectionReference,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [DocumentReference] {
        try validateDatabase(collection.database)
        return try await executeListDocuments(
            in: collection,
            pageSize: pageSize,
            readTime: readTime
        )
    }

    package func listen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        try validateDatabase(reference.database)
        return try await executeListen(to: reference)
    }

    package func getDocuments(for query: Query) async throws -> QuerySnapshot {
        try validateDatabase(query.database)
        return try await executeRunQuery(query)
    }

    package func listen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try validateDatabase(query.database)
        return try await executeListen(to: query)
    }

    package func aggregate(_ query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        try validateDatabase(query.database)
        return try await executeAggregate(query: query, fields: fields)
    }

    package func explain(_ query: Query, options: FirestoreExplainOptions) async throws -> QueryExplainResult {
        try validateDatabase(query.database)
        return try await executeExplain(query: query, options: options)
    }

    package func explainAggregation(
        _ query: Query,
        fields: [AggregateField],
        options: FirestoreExplainOptions
    ) async throws -> AggregateQueryExplainResult {
        try validateDatabase(query.database)
        return try await executeExplainAggregation(query: query, fields: fields, options: options)
    }

    package func partitionedQueries(
        for collectionGroup: CollectionGroup,
        partitionPointCount: Int,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [Query] {
        try validateDatabase(collectionGroup.database)
        return try await executePartitionedQueries(
            for: collectionGroup,
            partitionPointCount: partitionPointCount,
            pageSize: pageSize,
            readTime: readTime
        )
    }

    package func batchWrite(_ writes: [WriteData], labels: [String: String]) async throws -> FirestoreBulkWriteResult {
        try writes.forEach { try validateDatabase($0.documentReference.database) }
        return try await executeBatchWrite(writes: writes, labels: labels)
    }

    package func executePipeline(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        try await executePipelineQuery(pipeline)
    }

    package func explainPipeline(_ pipeline: FirestorePipeline, options: PipelineExplainOptions) async throws -> PipelineExplainResult {
        try await executePipelineExplainQuery(pipeline, options: options)
    }

    private func validateDatabase(_ other: Database) throws {
        guard other == database else {
            throw FirestoreError.databaseMismatch(expected: database.database, actual: other.database)
        }
    }
}
