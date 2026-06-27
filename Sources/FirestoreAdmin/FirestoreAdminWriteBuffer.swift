import Foundation
import FirestoreCore

final class FirestoreAdminWriteBuffer {
    private let database: Database
    private let allowsWrites: Bool
    private let disallowedWriteError: FirestoreError

    private var writes: [WriteData] = []
    private var validationError: FirestoreError?

    init(
        database: Database,
        allowsWrites: Bool = true,
        disallowedWriteError: FirestoreError = .readOnlyTransactionWrite
    ) {
        self.database = database
        self.allowsWrites = allowsWrites
        self.disallowedWriteError = disallowedWriteError
    }

    var isEmpty: Bool {
        writes.isEmpty
    }

    @discardableResult
    func appendCreate(data: [String: Any], for document: DocumentReference) -> Bool {
        append(.init(documentReference: document, data: data, merge: false, exist: false))
    }

    @discardableResult
    func appendSetData(_ data: [String: Any], for document: DocumentReference) -> Bool {
        append(.init(documentReference: document, data: data, merge: false))
    }

    @discardableResult
    func appendSetData(_ data: [String: Any], for document: DocumentReference, merge: Bool) -> Bool {
        append(.init(documentReference: document, data: data, merge: merge))
    }

    @discardableResult
    func appendSetData(
        _ data: [String: Any],
        for document: DocumentReference,
        mergeFields: [String]
    ) -> Bool {
        append(.init(documentReference: document, data: data, merge: true, mergeFields: mergeFields))
    }

    @discardableResult
    func appendUpdateData(_ fields: [String: Any], for document: DocumentReference) -> Bool {
        append(.init(documentReference: document, data: fields, merge: true, exist: true))
    }

    @discardableResult
    func appendDelete(_ document: DocumentReference) -> Bool {
        append(.init(documentReference: document, data: nil, merge: false))
    }

    func validateAppendTarget(_ document: DocumentReference) -> Bool {
        guard allowsWrites else {
            validationError = disallowedWriteError
            return false
        }
        guard document.database == database else {
            validationError = FirestoreError.databaseMismatch(
                expected: database.database,
                actual: document.database.database
            )
            return false
        }
        return true
    }

    func pendingWrites() throws -> [WriteData] {
        if let validationError {
            throw validationError
        }
        return writes
    }

    func removeAll() {
        writes.removeAll()
    }

    func reset() {
        writes.removeAll()
        validationError = nil
    }

    func validateNoPendingWrites() throws {
        guard writes.isEmpty else {
            throw FirestoreError.readAfterWriteError
        }
    }

    func validateDatabase(_ other: Database) throws {
        guard other == database else {
            throw FirestoreError.databaseMismatch(expected: database.database, actual: other.database)
        }
    }

    func validateNoDuplicateDocuments() throws {
        var seen: Set<String> = []
        for write in try pendingWrites() {
            let name = write.documentReference.name
            guard seen.insert(name).inserted else {
                throw FirestoreError.invalidOperation("BulkWriter cannot write to the same document more than once per flush.")
            }
        }
    }

    @discardableResult
    private func append(_ write: WriteData) -> Bool {
        guard validateAppendTarget(write.documentReference) else {
            return false
        }
        writes.append(write)
        return true
    }
}
