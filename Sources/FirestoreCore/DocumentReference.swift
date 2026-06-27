//
//  DocumentReference.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation

public struct DocumentReference: Sendable {

    package let database: Database
    private let parentPath: String
    package let runtime: (any FirestoreReferenceRuntime)?
    public let documentID: String
    public var path: String { "\(parentPath)/\(documentID)".normalized }
    package var name: String { "\(database.path)/\(path)".normalized }

    package init(_ database: Database, parentPath: String, documentID: String, runtime: (any FirestoreReferenceRuntime)? = nil) {
        self.database = database
        self.parentPath = parentPath
        self.runtime = runtime
        self.documentID = documentID
    }

    public init(projectId: String, databaseId: String = "(default)", path: String) throws {
        let database = Database(projectId: projectId, databaseId: databaseId)
        let (parentPath, documentID) = try FirestorePathValidator.documentPath(path)
        self.init(database, parentPath: parentPath, documentID: documentID)
    }

    package init(name: String, runtime: (any FirestoreReferenceRuntime)? = nil) throws {
        let components = name
            .split(separator: "/", omittingEmptySubsequences: false)
            .map(String.init)
        guard components.count >= 7,
              components[0] == "projects",
              components[2] == "databases",
              components[4] == "documents",
              !components[1].isEmpty,
              !components[3].isEmpty
        else {
            throw FirestoreError.invalidPath("Document name must be a valid Firestore document resource name.")
        }

        let projectID = String(components[1])
        let databaseID = String(components[3])
        let database = Database(projectId: projectID, databaseId: databaseID)
        let documentPath = components.dropFirst(5).joined(separator: "/")
        let (parentPath, documentID) = try FirestorePathValidator.documentPath(documentPath)
        self.init(database, parentPath: parentPath, documentID: documentID, runtime: runtime)
    }

    public var parent: CollectionReference {
        let components = parentPath
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        guard let lastComponent = components.last else {
            return CollectionReference(database, parentPath: nil, collectionID: parentPath, runtime: runtime)
        }
        let parentPath = components.dropLast(1).joined(separator: "/")
        let collectionID = String(lastComponent)
        return CollectionReference(database, parentPath: parentPath, collectionID: collectionID, runtime: runtime)
    }

    public func collection(_ collectionPath: String) throws -> CollectionReference {
        let (parentPath, collectionID) = try FirestorePathValidator.childCollectionPath(
            collectionPath,
            parentDocumentPath: path
        )
        return CollectionReference(database, parentPath: parentPath, collectionID: collectionID, runtime: runtime)
    }

    public func getDocument() async throws -> DocumentSnapshot {
        try await getDocument(source: .default)
    }

    public func getDocument(source: FirestoreSource) async throws -> DocumentSnapshot {
        try source.validateServerSideRead()
        return try await requireRuntime().getDocument(self)
    }

    public func setData(_ documentData: [String: Any], merge: Bool = false) async throws {
        try await requireRuntime().setData(documentData, merge: merge, for: self)
    }

    public func setData(_ documentData: [String: Any], mergeFields: [String]) async throws {
        try await requireRuntime().setData(documentData, mergeFields: mergeFields, for: self)
    }

    public func setData(_ documentData: [String: Any], mergeFields: [FieldPath]) async throws {
        let encodedFieldPaths = try FirestoreFieldPath.encodeFieldPaths(mergeFields)
        try await setData(documentData, mergeFields: encodedFieldPaths)
    }

    public func updateData(_ fields: [String: Any]) async throws {
        try await requireRuntime().updateData(fields, for: self)
    }

    public func updateData(_ fields: [FieldPath: Any]) async throws {
        try await updateData(FirestoreFieldPath.encodeFieldPathDictionary(fields))
    }

    public func delete() async throws {
        try await requireRuntime().deleteDocument(self)
    }

    public func listCollections() async throws -> [CollectionReference] {
        try await requireRuntime().listCollections(in: self)
    }

    public var snapshots: FirestoreSnapshotSequence<DocumentSnapshot> {
        snapshots(options: SnapshotListenOptions())
    }

    public func snapshots(
        includeMetadataChanges: Bool
    ) -> FirestoreSnapshotSequence<DocumentSnapshot> {
        snapshots(
            options: SnapshotListenOptions(includeMetadataChanges: includeMetadataChanges)
        )
    }

    public func snapshots(
        options: SnapshotListenOptions
    ) -> FirestoreSnapshotSequence<DocumentSnapshot> {
        FirestoreSnapshotSequence {
            try await addSnapshotListener(options: options)
        }
    }

    public func addSnapshotListener() async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        try await addSnapshotListener(options: SnapshotListenOptions())
    }

    public func addSnapshotListener(
        includeMetadataChanges: Bool
    ) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        try await addSnapshotListener(
            options: SnapshotListenOptions(includeMetadataChanges: includeMetadataChanges)
        )
    }

    public func addSnapshotListener(
        options: SnapshotListenOptions
    ) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        try options.validateServerSide()
        return try await requireRuntime().listen(to: self)
    }

    private func requireRuntime() throws -> any FirestoreDocumentRuntime {
        guard let runtime else {
            throw FirestoreError.unboundReference("DocumentReference is not bound to a Firestore runtime. Create a runtime-bound reference before performing server operations.")
        }
        return runtime
    }
}

extension DocumentReference: Hashable {
    public static func == (lhs: DocumentReference, rhs: DocumentReference) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension DocumentReference: Codable {
    enum CodingKeys: CodingKey {
        case database
        case path
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(database, forKey: .database)
        try container.encode(path, forKey: .path)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let database = try container.decode(Database.self, forKey: .database)
        let path = try container.decode(String.self, forKey: .path)
        let (parentPath, documentID) = try FirestorePathValidator.documentPath(path)
        self.init(database, parentPath: parentPath, documentID: documentID)
    }
}
