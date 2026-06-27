//
//  CollectionReference.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation

public struct CollectionReference: Sendable {

    package let database: Database
    package let parentPath: String?
    package let runtime: (any FirestoreReferenceRuntime)?
    public let collectionID: String

    public var path: String {
        if let parentPath {
            return "\(parentPath)/\(collectionID)".normalized
        } else {
            return "\(collectionID)".normalized
        }
    }

    package var name: String {
        if let parentPath {
            return "\(database.path)/\(parentPath)".normalized
        }
        return "\(database.path)".normalized
    }

    package init(_ database: Database, parentPath: String?, collectionID: String, runtime: (any FirestoreReferenceRuntime)? = nil) {
        self.database = database
        self.parentPath = parentPath
        self.runtime = runtime
        self.collectionID = collectionID
    }

    public init(projectId: String, databaseId: String = "(default)", path: String) throws {
        let database = Database(projectId: projectId, databaseId: databaseId)
        let (parentPath, collectionID) = try FirestorePathValidator.collectionPath(path)
        self.init(database, parentPath: parentPath, collectionID: collectionID)
    }

    public var parent: DocumentReference? {
        guard let parentPath else { return nil }
        let components = parentPath
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        guard let lastComponent = components.last else { return nil }

        let documentID = String(lastComponent)
        let parentPathForDocument = components.dropLast(1).joined(separator: "/")
        return DocumentReference(database, parentPath: parentPathForDocument, documentID: documentID, runtime: runtime)
    }

    public func document() throws -> DocumentReference {
        try document(IDGenerator.generate())
    }

    public func document(_ id: String) throws -> DocumentReference {
        let (parentPath, documentID) = try FirestorePathValidator.childDocumentPath(
            id,
            parentCollectionPath: path
        )
        return DocumentReference(database, parentPath: parentPath, documentID: documentID, runtime: runtime)
    }

    public func addDocument(data: [String: Any]) async throws -> DocumentReference {
        let documentRef = try document()
        try await documentRef.setData(data)
        return documentRef
    }

    public func getDocuments() async throws -> QuerySnapshot {
        try await getDocuments(source: .default)
    }

    public func getDocuments(source: FirestoreSource) async throws -> QuerySnapshot {
        try await toQuery().getDocuments(source: source)
    }

    public func listDocuments(
        pageSize: Int = 0,
        readTime: Timestamp? = nil
    ) async throws -> [DocumentReference] {
        try await requireRuntime().listDocuments(
            in: self,
            pageSize: pageSize,
            readTime: readTime
        )
    }

    public func count() async throws -> Int {
        try await toQuery().count()
    }

    public func aggregate(_ fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        try await toQuery().aggregate(fields)
    }

    public func explain(
        options: FirestoreExplainOptions = .planOnly
    ) async throws -> QueryExplainResult {
        try await toQuery().explain(options: options)
    }

    public func explainAggregation(
        _ fields: [AggregateField],
        options: FirestoreExplainOptions = .planOnly
    ) async throws -> AggregateQueryExplainResult {
        try await toQuery().explainAggregation(fields, options: options)
    }

    public func sum(_ field: String) async throws -> AggregateValue {
        try await toQuery().sum(field)
    }

    public func sum(_ field: FieldPath) async throws -> AggregateValue {
        try await toQuery().sum(field)
    }

    public func average(_ field: String) async throws -> Double? {
        try await toQuery().average(field)
    }

    public func average(_ field: FieldPath) async throws -> Double? {
        try await toQuery().average(field)
    }

    public var snapshots: FirestoreSnapshotSequence<QuerySnapshot> {
        toQuery().snapshots
    }

    public func snapshots(
        includeMetadataChanges: Bool
    ) -> FirestoreSnapshotSequence<QuerySnapshot> {
        toQuery().snapshots(includeMetadataChanges: includeMetadataChanges)
    }

    public func snapshots(
        options: SnapshotListenOptions
    ) -> FirestoreSnapshotSequence<QuerySnapshot> {
        toQuery().snapshots(options: options)
    }

    public func addSnapshotListener() async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try await toQuery().addSnapshotListener()
    }

    public func addSnapshotListener(
        includeMetadataChanges: Bool
    ) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try await toQuery().addSnapshotListener(includeMetadataChanges: includeMetadataChanges)
    }

    public func addSnapshotListener(
        options: SnapshotListenOptions
    ) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try await toQuery().addSnapshotListener(options: options)
    }

    public func findNearest(
        vectorField: String,
        queryVector: FirestoreVector,
        limit: Int,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        distanceResultField: String? = nil,
        distanceThreshold: Double? = nil
    ) -> Query {
        toQuery().findNearest(
            vectorField: vectorField,
            queryVector: queryVector,
            limit: limit,
            distanceMeasure: distanceMeasure,
            distanceResultField: distanceResultField,
            distanceThreshold: distanceThreshold
        )
    }

    public func findNearest(
        vectorField: FieldPath,
        queryVector: FirestoreVector,
        limit: Int,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        distanceResultField: String? = nil,
        distanceThreshold: Double? = nil
    ) throws -> Query {
        try toQuery().findNearest(
            vectorField: vectorField,
            queryVector: queryVector,
            limit: limit,
            distanceMeasure: distanceMeasure,
            distanceResultField: distanceResultField,
            distanceThreshold: distanceThreshold
        )
    }

    private func requireRuntime() throws -> any FirestoreCollectionRuntime {
        guard let runtime else {
            throw FirestoreError.unboundReference("CollectionReference is not bound to a Firestore runtime. Create a runtime-bound reference before performing server operations.")
        }
        return runtime
    }
}

extension CollectionReference {
    package func toQuery() -> Query {
        return Query(database, parentPath: parentPath, collectionID: collectionID, allDescendants: false, predicates: [], runtime: runtime)
    }

    package func makeQuery(predicates: [QueryPredicate]) -> Query {
        return Query(database, parentPath: parentPath, collectionID: collectionID, allDescendants: false, predicates: predicates, runtime: runtime)
    }
}

extension CollectionReference: Codable {

    enum CodingKeys: CodingKey {
        case database
        case parentPath
        case collectionID
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(database, forKey: .database)
        try container.encode(parentPath, forKey: .parentPath)
        try container.encode(collectionID, forKey: .collectionID)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let database = try container.decode(Database.self, forKey: .database)
        let decodedParentPath = try container.decodeIfPresent(String.self, forKey: .parentPath)
        let decodedCollectionID = try container.decode(String.self, forKey: .collectionID)
        let collectionID = try FirestorePathValidator.collectionGroupID(decodedCollectionID)
        let collectionPath = [decodedParentPath, collectionID]
            .compactMap { $0 }
            .joined(separator: "/")
        let (parentPath, validatedCollectionID) = try FirestorePathValidator.collectionPath(collectionPath)
        self.init(database, parentPath: parentPath, collectionID: validatedCollectionID)
    }
}
