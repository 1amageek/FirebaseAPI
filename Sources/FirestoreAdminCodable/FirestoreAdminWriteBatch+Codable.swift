import Foundation
import FirestoreAdmin
import FirestoreCodable
import FirestoreCore

extension FirestoreAdminWriteBatch {
    @discardableResult
    public func create<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> FirestoreAdminWriteBatch {
        guard canAppend(to: document) else {
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        return create(data: documentData, forDocument: document)
    }

    @discardableResult
    public func setData<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> FirestoreAdminWriteBatch {
        guard canAppend(to: document) else {
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        return setData(documentData, forDocument: document)
    }

    @discardableResult
    public func setData<T: Encodable>(
        from data: T,
        forDocument document: DocumentReference,
        merge: Bool
    ) throws -> FirestoreAdminWriteBatch {
        guard canAppend(to: document) else {
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        return setData(documentData, forDocument: document, merge: merge)
    }

    @discardableResult
    public func setData<T: Encodable>(
        from data: T,
        forDocument document: DocumentReference,
        mergeFields: [String]
    ) throws -> FirestoreAdminWriteBatch {
        guard canAppend(to: document) else {
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        return setData(documentData, forDocument: document, mergeFields: mergeFields)
    }

    @discardableResult
    public func setData<T: Encodable>(
        from data: T,
        forDocument document: DocumentReference,
        mergeFields: [FieldPath]
    ) throws -> FirestoreAdminWriteBatch {
        guard canAppend(to: document) else {
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        return try setData(documentData, forDocument: document, mergeFields: mergeFields)
    }

    @discardableResult
    public func updateData<T: Encodable>(
        from fields: T,
        forDocument document: DocumentReference
    ) throws -> FirestoreAdminWriteBatch {
        guard canAppend(to: document) else {
            return self
        }
        let documentData = try FirestoreEncoder().encode(fields)
        return updateData(documentData, forDocument: document)
    }
}
