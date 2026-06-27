import Foundation
import FirestoreAdmin
import FirestoreCodable
import FirestoreCore

extension FirestoreAdminTransaction {
    public func getDocument<T: Decodable>(_ document: DocumentReference, type: T.Type) async throws -> T? {
        let snapshot = try await getDocument(document)
        return try snapshot.data(as: type)
    }

    public func getDocument<T: Decodable>(_ document: DocumentReference, as type: T.Type) async throws -> T? {
        try await getDocument(document, type: type)
    }

    public func get<T: Decodable>(query: Query, type: T.Type) async throws -> [T] {
        let snapshot = try await get(query: query)
        return try snapshot.documents(as: type)
    }

    public func get<T: Decodable>(query: Query, as type: T.Type) async throws -> [T] {
        try await get(query: query, type: type)
    }

    @discardableResult
    public func create<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> FirestoreAdminTransaction {
        let documentData = try FirestoreEncoder().encode(data)
        return create(data: documentData, forDocument: document)
    }

    @discardableResult
    public func setData<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> FirestoreAdminTransaction {
        let documentData = try FirestoreEncoder().encode(data)
        return setData(documentData, forDocument: document)
    }

    @discardableResult
    public func setData<T: Encodable>(
        from data: T,
        forDocument document: DocumentReference,
        merge: Bool
    ) throws -> FirestoreAdminTransaction {
        let documentData = try FirestoreEncoder().encode(data)
        return setData(documentData, forDocument: document, merge: merge)
    }

    @discardableResult
    public func setData<T: Encodable>(
        from data: T,
        forDocument document: DocumentReference,
        mergeFields: [String]
    ) throws -> FirestoreAdminTransaction {
        let documentData = try FirestoreEncoder().encode(data)
        return setData(documentData, forDocument: document, mergeFields: mergeFields)
    }

    @discardableResult
    public func setData<T: Encodable>(
        from data: T,
        forDocument document: DocumentReference,
        mergeFields: [FieldPath]
    ) throws -> FirestoreAdminTransaction {
        let documentData = try FirestoreEncoder().encode(data)
        return try setData(documentData, forDocument: document, mergeFields: mergeFields)
    }

    @discardableResult
    public func updateData<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> FirestoreAdminTransaction {
        let documentData = try FirestoreEncoder().encode(data)
        return updateData(documentData, forDocument: document)
    }
}
