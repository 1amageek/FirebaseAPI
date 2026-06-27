import Foundation
import FirestoreCore

public final class FirestoreAdminBulkWriter {
    private let writeBuffer: FirestoreAdminWriteBuffer
    private let flushHandler: ([WriteData], [String: String]) async throws -> FirestoreBulkWriteResult

    init(
        database: Database,
        flushHandler: @escaping ([WriteData], [String: String]) async throws -> FirestoreBulkWriteResult
    ) {
        self.writeBuffer = FirestoreAdminWriteBuffer(database: database)
        self.flushHandler = flushHandler
    }

    /// Creates an unbound bulk writer for custom Admin clients and test doubles.
    ///
    /// Use `FirestoreAdmin.bulkWriter()` for runtime-backed server writes.
    public convenience init(
        projectId: String,
        databaseId: String = "(default)",
        onFlush: @escaping ([FirestoreAdminWriteOperation], [String: String]) async throws -> FirestoreBulkWriteResult = { operations, _ in
            FirestoreBulkWriteResult(
                results: operations.enumerated().map { index, operation in
                    FirestoreBulkWriteOperationResult(
                        index: index,
                        document: operation.document,
                        updateTime: nil,
                        error: nil
                    )
                }
            )
        }
    ) {
        self.init(database: Database(projectId: projectId, databaseId: databaseId)) { writes, labels in
            try await onFlush(writes.map(FirestoreAdminWriteOperation.init(write:)), labels)
        }
    }

    package func canAppend(to document: DocumentReference) -> Bool {
        writeBuffer.validateAppendTarget(document)
    }

    @discardableResult
    public func create(data: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminBulkWriter {
        writeBuffer.appendCreate(data: data, for: document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminBulkWriter {
        writeBuffer.appendSetData(data, for: document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, merge: Bool) -> FirestoreAdminBulkWriter {
        writeBuffer.appendSetData(data, for: document, merge: merge)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, mergeFields: [String]) -> FirestoreAdminBulkWriter {
        writeBuffer.appendSetData(data, for: document, mergeFields: mergeFields)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, mergeFields: [FieldPath]) throws -> FirestoreAdminBulkWriter {
        setData(data, forDocument: document, mergeFields: try FirestoreFieldPath.encodeFieldPaths(mergeFields))
    }

    @discardableResult
    public func updateData(_ fields: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminBulkWriter {
        writeBuffer.appendUpdateData(fields, for: document)
        return self
    }

    @discardableResult
    public func updateData(_ fields: [FieldPath: Any], forDocument document: DocumentReference) throws -> FirestoreAdminBulkWriter {
        updateData(try FirestoreFieldPath.encodeFieldPathDictionary(fields), forDocument: document)
    }

    @discardableResult
    public func deleteDocument(_ document: DocumentReference) -> FirestoreAdminBulkWriter {
        writeBuffer.appendDelete(document)
        return self
    }

    public func flush(labels: [String: String] = [:]) async throws -> FirestoreBulkWriteResult {
        try writeBuffer.validateNoDuplicateDocuments()
        guard !writeBuffer.isEmpty else {
            return FirestoreBulkWriteResult(results: [])
        }

        let flushedWrites = try writeBuffer.pendingWrites()
        writeBuffer.removeAll()
        return try await flushHandler(flushedWrites, labels)
    }
}
