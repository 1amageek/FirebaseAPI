import Foundation
import FirestoreCore

extension DocumentReference {
    public func getDocument<T: Decodable>(type: T.Type) async throws -> T? {
        try await getDocument(type: type, source: .default)
    }

    public func getDocument<T: Decodable>(type: T.Type, source: FirestoreSource) async throws -> T? {
        let snapshot = try await getDocument(source: source)
        return try snapshot.data(as: type)
    }

    public func getDocument<T: Decodable>(as type: T.Type) async throws -> T? {
        try await getDocument(type: type)
    }

    public func getDocument<T: Decodable>(as type: T.Type, source: FirestoreSource) async throws -> T? {
        try await getDocument(type: type, source: source)
    }

    public func setData<T: Encodable>(_ data: T, merge: Bool = false) async throws {
        let documentData = try FirestoreEncoder().encode(data)
        try await setData(documentData, merge: merge)
    }

    public func setData<T: Encodable>(from data: T, merge: Bool = false) async throws {
        try await setData(data, merge: merge)
    }

    public func setData<T: Encodable>(_ data: T, mergeFields: [String]) async throws {
        let documentData = try FirestoreEncoder().encode(data)
        try await setData(documentData, mergeFields: mergeFields)
    }

    public func setData<T: Encodable>(from data: T, mergeFields: [String]) async throws {
        try await setData(data, mergeFields: mergeFields)
    }

    public func setData<T: Encodable>(_ data: T, mergeFields: [FieldPath]) async throws {
        let documentData = try FirestoreEncoder().encode(data)
        try await setData(documentData, mergeFields: mergeFields)
    }

    public func setData<T: Encodable>(from data: T, mergeFields: [FieldPath]) async throws {
        try await setData(data, mergeFields: mergeFields)
    }

    public func updateData<T: Encodable>(_ fields: T) async throws {
        let encodedFields = try FirestoreEncoder().encode(fields)
        try await updateData(encodedFields)
    }
}
