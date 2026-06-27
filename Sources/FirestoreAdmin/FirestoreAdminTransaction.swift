import Foundation
import FirestoreCore
import FirestoreRuntimeSupport

public final class FirestoreAdminTransaction {
    private let runtime: any FirestoreTransactionRuntime
    private let writeBuffer: FirestoreAdminWriteBuffer

    private var id: Data?

    let backoff: FirestoreTransactionBackoff
    var options: TransactionOptions

    var hasTransactionID: Bool {
        id != nil
    }

    var transactionID: Data? {
        id
    }

    init(
        database: Database,
        runtime: any FirestoreTransactionRuntime,
        options: TransactionOptions = TransactionOptions(maxAttempts: 5, readOnly: false)
    ) {
        self.runtime = runtime
        self.writeBuffer = FirestoreAdminWriteBuffer(
            database: database,
            allowsWrites: !options.readOnly,
            disallowedWriteError: .readOnlyTransactionWrite
        )
        self.options = options
        self.backoff = FirestoreTransactionBackoff(maxAttempts: options.maxAttempts)
    }

    public func getDocument(_ document: DocumentReference) async throws -> DocumentSnapshot {
        let snapshots = try await getAll(documentReferences: document)
        guard let snapshot = snapshots.first else {
            throw FirestoreError.noResult
        }
        return snapshot
    }

    public func get(query: Query) async throws -> QuerySnapshot {
        try writeBuffer.validateNoPendingWrites()
        try writeBuffer.validateDatabase(query.database)
        return try await runtime.runQuery(query: query, transactionID: id)
    }

    public func getAll(documentReferences: DocumentReference...) async throws -> [DocumentSnapshot] {
        try writeBuffer.validateNoPendingWrites()
        guard !documentReferences.isEmpty else {
            throw FirestoreError.minNumberOfArgumentsError
        }
        for documentReference in documentReferences {
            try writeBuffer.validateDatabase(documentReference.database)
        }
        return try await runtime.batchGetDocuments(documentReferences: documentReferences, transactionID: id)
    }

    @discardableResult
    public func create(data: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminTransaction {
        writeBuffer.appendCreate(data: data, for: document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminTransaction {
        writeBuffer.appendSetData(data, for: document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, merge: Bool) -> FirestoreAdminTransaction {
        writeBuffer.appendSetData(data, for: document, merge: merge)
        return self
    }

    @discardableResult
    public func updateData(_ fields: [String: Any], forDocument document: DocumentReference) -> FirestoreAdminTransaction {
        writeBuffer.appendUpdateData(fields, for: document)
        return self
    }

    @discardableResult
    public func updateData(_ fields: [FieldPath: Any], forDocument document: DocumentReference) throws -> FirestoreAdminTransaction {
        updateData(try FirestoreFieldPath.encodeFieldPathDictionary(fields), forDocument: document)
    }

    @discardableResult
    public func deleteDocument(_ document: DocumentReference) -> FirestoreAdminTransaction {
        writeBuffer.appendDelete(document)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, mergeFields: [String]) -> FirestoreAdminTransaction {
        writeBuffer.appendSetData(data, for: document, mergeFields: mergeFields)
        return self
    }

    @discardableResult
    public func setData(_ data: [String: Any], forDocument document: DocumentReference, mergeFields: [FieldPath]) throws -> FirestoreAdminTransaction {
        setData(
            data,
            forDocument: document,
            mergeFields: try FirestoreFieldPath.encodeFieldPaths(mergeFields)
        )
    }

    func begin(readOnly: Bool, readTime: Timestamp?, retryTransactionID: Data? = nil) async throws {
        id = nil
        let retryTransactionID = readOnly ? nil : retryTransactionID
        id = try await runtime.beginTransactionID(
            readOnly: readOnly,
            readTime: readTime,
            retryTransactionID: retryTransactionID
        )
        writeBuffer.reset()
    }

    func commit() async throws {
        let (id, writes) = try validateReadyToComplete()
        let didCommit = try await runtime.commitWrites(writes, transactionID: id)
        if !didCommit {
            throw FirestoreError.commitFailed
        }
    }

    func completeReadOnly() throws {
        _ = try validateReadyToComplete()
    }

    func rollback() async throws {
        guard let id else {
            throw TransactionError.missingTransactionID
        }
        try await runtime.rollbackTransactionID(transactionID: id)
    }

    private func validateReadyToComplete() throws -> (Data, [WriteData]) {
        let writes = try writeBuffer.pendingWrites()
        guard let id else {
            throw TransactionError.missingTransactionID
        }
        return (id, writes)
    }
}
