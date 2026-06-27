import Foundation
import FirestoreCore

extension CollectionGroup {
    public func getDocuments<T: Decodable>(type: T.Type) async throws -> [T] {
        try await getDocuments(type: type, source: .default)
    }

    public func getDocuments<T: Decodable>(type: T.Type, source: FirestoreSource) async throws -> [T] {
        let snapshot = try await getDocuments(source: source)
        return try snapshot.documents(as: type)
    }

    public func getDocuments<T: Decodable>(as type: T.Type) async throws -> [T] {
        try await getDocuments(type: type)
    }

    public func getDocuments<T: Decodable>(as type: T.Type, source: FirestoreSource) async throws -> [T] {
        try await getDocuments(type: type, source: source)
    }
}
