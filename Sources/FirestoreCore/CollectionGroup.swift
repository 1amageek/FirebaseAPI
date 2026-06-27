//
//  CollectionGroup.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/11.
//

import Foundation

/**
 A group of collections in a Firestore database.

 Use a `CollectionGroup` instance to perform queries across multiple collections that share the same subcollection name.

 For example, consider a database with the following collections:

 - `users/{userID}/posts/{postID}`
 - `groups/{groupID}/posts/{postID}`
 - `companies/{companyID}/employees/{employeeID}/projects/{projectID}/tasks/{taskID}`

 Each collection has a subcollection named `posts`. You can use a `CollectionGroup` instance to query all posts across all collections with the subcollection name `posts`.

 You must create collection groups from a runtime-bound client so server operations can use the bound runtime.

 */
public struct CollectionGroup {

    /// The database associated with the collection group.
    package let database: Database
    package let runtime: (any FirestoreCollectionGroupRuntime)?

    /// The ID of the collection group.
    public let groupID: String

    /**
     Initializes a new `CollectionGroup` instance with the specified database and group ID.

     - Parameters:
        - database: The database associated with the collection group.
        - groupID: The ID of the collection group.
     */
    package init(_ database: Database, groupID: String, runtime: (any FirestoreCollectionGroupRuntime)? = nil) {
        self.database = database
        self.groupID = groupID
        self.runtime = runtime
    }

    public init(projectId: String, databaseId: String = "(default)", groupID: String) throws {
        let database = Database(projectId: projectId, databaseId: databaseId)
        self.init(database, groupID: try FirestorePathValidator.collectionGroupID(groupID))
    }

    public func getDocuments() async throws -> QuerySnapshot {
        try await getDocuments(source: .default)
    }

    public func getDocuments(source: FirestoreSource) async throws -> QuerySnapshot {
        try await toQuery().getDocuments(source: source)
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

    public func count() async throws -> Int {
        try await toQuery().count()
    }

    public func partitionedQueries(
        partitionPointCount: Int,
        pageSize: Int = 0,
        readTime: Timestamp? = nil
    ) async throws -> [Query] {
        try await requireRuntime().partitionedQueries(
            for: self,
            partitionPointCount: partitionPointCount,
            pageSize: pageSize,
            readTime: readTime
        )
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

    private func requireRuntime() throws -> any FirestorePartitionQueryRuntime {
        guard let runtime else {
            throw FirestoreError.unboundReference("CollectionGroup is not bound to a Firestore runtime. Create a runtime-bound collection group before performing server operations.")
        }
        return runtime
    }
}
