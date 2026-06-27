import Foundation
import FirestoreCore

public final class FirestoreAdminWriteBatch {
    private let writeBuffer: FirestoreAdminWriteBuffer
    private let commitHandler: ([WriteData]) async throws -> Void

    private var hasCommitted = false

    package init(
        database: Database,
        commitHandler: @escaping ([WriteData]) async throws -> Void
    ) {
        self.writeBuffer = FirestoreAdminWriteBuffer(database: database)
        self.commitHandler = commitHandler
    }

    /// Creates an unbound batch for custom Admin clients and test doubles.
    ///
    /// Use `FirestoreAdmin.batch()` for runtime-backed server writes.
    public convenience init(
        projectId: String,
        databaseId: String = "(default)",
        onCommit: @escaping ([FirestoreAdminWriteOperation]) async throws -> Void = { _ in }
    ) {
        self.init(database: Database(projectId: projectId, databaseId: databaseId)) { writes in
            try await onCommit(writes.map(FirestoreAdminWriteOperation.init(write:)))
        }
    }

    package func canAppend(to document: DocumentReference) -> Bool {
        writeBuffer.validateAppendTarget(document)
    }

    @discardableResult
    public func create(data: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminWriteBatch {
        writeBuffer.appendCreate(data: data, for: document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminWriteBatch {
        writeBuffer.appendSetData(data, for: document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, merge: Bool) -> FirestoreAdminWriteBatch {
        writeBuffer.appendSetData(data, for: document, merge: merge)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, mergeFields: [String]) -> FirestoreAdminWriteBatch {
        writeBuffer.appendSetData(data, for: document, mergeFields: mergeFields)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, mergeFields: [FieldPath]) throws -> FirestoreAdminWriteBatch {
        setData(data, forDocument: document, mergeFields: try FirestoreFieldPath.encodeFieldPaths(mergeFields))
    }

    @discardableResult
    public func updateData(_ fields: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminWriteBatch {
        writeBuffer.appendUpdateData(fields, for: document)
        return self
    }

    @discardableResult
    public func updateData(_ fields: [FieldPath: Any], forDocument document: DocumentReference) throws -> FirestoreAdminWriteBatch {
        updateData(try FirestoreFieldPath.encodeFieldPathDictionary(fields), forDocument: document)
    }

    @discardableResult
    public func deleteDocument(_ document: DocumentReference) -> FirestoreAdminWriteBatch {
        writeBuffer.appendDelete(document)
        return self
    }

    public func commit() async throws {
        let writes = try writeBuffer.pendingWrites()
        guard !hasCommitted else {
            throw FirestoreError.invalidOperation("Write batch has already been committed.")
        }
        hasCommitted = true
        try await commitHandler(writes)
    }
}
