//
//  Query.swift
//
//
//  Created by nori on 2022/05/16.
//

import Foundation

public struct Query {

    package let database: Database
    package let parentPath: String?
    public let collectionID: String
    package let allDescendants: Bool
    package let predicates: [QueryPredicate]
    package let runtime: (any FirestoreQueryRuntime)?

    public var path: String {
        if let parentPath {
            return "\(parentPath)/\(collectionID)".normalized
        } else {
            return "\(collectionID)".normalized
        }
    }

    package init(
        _ database: Database,
        parentPath: String?,
        collectionID: String,
        allDescendants: Bool = false,
        predicates: [QueryPredicate],
        runtime: (any FirestoreQueryRuntime)? = nil
    ) {
        self.database = database
        self.parentPath = parentPath
        self.allDescendants = allDescendants
        self.collectionID = collectionID
        self.predicates = predicates
        self.runtime = runtime
    }

    public func getDocuments() async throws -> QuerySnapshot {
        try await getDocuments(source: .default)
    }

    public func getDocuments(source: FirestoreSource) async throws -> QuerySnapshot {
        try source.validateServerSideRead()
        return try await requireRuntime().getDocuments(for: self)
    }

    public var snapshots: FirestoreSnapshotSequence<QuerySnapshot> {
        snapshots(options: SnapshotListenOptions())
    }

    public func snapshots(
        includeMetadataChanges: Bool
    ) -> FirestoreSnapshotSequence<QuerySnapshot> {
        snapshots(
            options: SnapshotListenOptions(includeMetadataChanges: includeMetadataChanges)
        )
    }

    public func snapshots(
        options: SnapshotListenOptions
    ) -> FirestoreSnapshotSequence<QuerySnapshot> {
        FirestoreSnapshotSequence {
            try await addSnapshotListener(options: options)
        }
    }

    public func addSnapshotListener() async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try await addSnapshotListener(options: SnapshotListenOptions())
    }

    public func addSnapshotListener(
        includeMetadataChanges: Bool
    ) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try await addSnapshotListener(
            options: SnapshotListenOptions(includeMetadataChanges: includeMetadataChanges)
        )
    }

    public func addSnapshotListener(
        options: SnapshotListenOptions
    ) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        try options.validateServerSide()
        return try await requireRuntime().listen(to: self)
    }

    public func aggregate(_ fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        try await requireRuntime().aggregate(self, fields: fields)
    }

    public func explain(
        options: FirestoreExplainOptions = .planOnly
    ) async throws -> QueryExplainResult {
        try await requireRuntime().explain(self, options: options)
    }

    public func explainAggregation(
        _ fields: [AggregateField],
        options: FirestoreExplainOptions = .planOnly
    ) async throws -> AggregateQueryExplainResult {
        try await requireRuntime().explainAggregation(self, fields: fields, options: options)
    }

    public func count() async throws -> Int {
        let field = AggregateField.count()
        let snapshot = try await aggregate([field])
        return Int(try snapshot.requireInteger(field))
    }

    public func sum(_ field: String) async throws -> AggregateValue {
        let aggregateField = AggregateField.sum(field)
        let snapshot = try await aggregate([aggregateField])
        return try snapshot.requireNumeric(aggregateField)
    }

    public func sum(_ field: FieldPath) async throws -> AggregateValue {
        let aggregateField = try AggregateField.sum(field)
        let snapshot = try await aggregate([aggregateField])
        return try snapshot.requireNumeric(aggregateField)
    }

    public func average(_ field: String) async throws -> Double? {
        let aggregateField = AggregateField.average(field)
        let snapshot = try await aggregate([aggregateField])
        return try snapshot.requireNumeric(aggregateField).doubleValue
    }

    public func average(_ field: FieldPath) async throws -> Double? {
        let aggregateField = try AggregateField.average(field)
        let snapshot = try await aggregate([aggregateField])
        return try snapshot.requireNumeric(aggregateField).doubleValue
    }

    private func requireRuntime() throws -> any FirestoreQueryRuntime {
        guard let runtime else {
            throw FirestoreError.unboundReference("Query is not bound to a Firestore runtime. Create a runtime-bound query before performing server operations.")
        }
        return runtime
    }
}

extension Query {
    package func copy(predicates: [QueryPredicate]) -> Query {
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates, runtime: runtime)
    }

    package var name: String {
        if let parentPath {
            return "\(database.path)/\(parentPath)".normalized
        }
        return "\(database.path)".normalized
    }
}

extension Query {
    public func whereFilter(_ filter: Filter) -> Query {
        copy(predicates: append(filter.predicate))
    }

    package func or(_ filters: [QueryPredicate]) -> Query {
        copy(predicates: append(.or(filters)))
    }

    package func and(_ filters: [QueryPredicate]) -> Query {
        copy(predicates: append(.and(filters)))
    }
}

extension Query {
    package func append(_ predicate: QueryPredicate) -> [QueryPredicate] {
        var predicates = self.predicates
        if let compositeIndex = predicates.firstIndex(where: { $0.type == .compositeFilter }) {
            let compositeFilter = predicates[compositeIndex]
            if case .and(let filters) = compositeFilter {
                var newFilters = filters
                newFilters.append(predicate)
                predicates[compositeIndex] = .and(newFilters)
                return predicates
            }
            if case .or(_) = compositeFilter {
                predicates[compositeIndex] = .and([compositeFilter, predicate])
                return predicates
            }
        } else if let filterIndex = predicates.firstIndex(where: { $0.type == .fieldFilter || $0.type == .unaryFilter }) {
            let filter = predicates[filterIndex]
            predicates[filterIndex] = .and([filter, predicate])
            return predicates
        }
        predicates.append(predicate)
        return predicates
    }
}

extension Query {
    public func findNearest(
        vectorField: String,
        queryVector: FirestoreVector,
        limit: Int,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        distanceResultField: String? = nil,
        distanceThreshold: Double? = nil
    ) -> Query {
        var predicates = self.predicates
        predicates.append(
            .findNearest(
                FirestoreFindNearestQuery(
                    vectorField: vectorField,
                    queryVector: queryVector,
                    limit: limit,
                    distanceMeasure: distanceMeasure,
                    distanceResultField: distanceResultField,
                    distanceThreshold: distanceThreshold
                )
            )
        )
        return copy(predicates: predicates)
    }

    public func findNearest(
        vectorField: FieldPath,
        queryVector: FirestoreVector,
        limit: Int,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        distanceResultField: String? = nil,
        distanceThreshold: Double? = nil
    ) throws -> Query {
        var predicates = self.predicates
        predicates.append(
            try .findNearest(
                fieldPath: vectorField,
                queryVector: queryVector,
                limit: limit,
                distanceMeasure: distanceMeasure,
                distanceResultField: distanceResultField,
                distanceThreshold: distanceThreshold
            )
        )
        return copy(predicates: predicates)
    }
}

extension Query {
    public func limit(to value: Int) -> Query {
        var predicates = self.predicates
        predicates.append(.limitTo(value))
        return copy(predicates: predicates)
    }

    public func limit(toLast value: Int) -> Query {
        var predicates = self.predicates
        predicates.append(.limitToLast(value))
        return copy(predicates: predicates)
    }
}

extension Query {
    public func order(by field: String, descending: Bool = false) -> Query {
        var predicates = self.predicates
        predicates.append(.orderBy(field, descending))
        return copy(predicates: predicates)
    }

    public func order(by field: FieldPath, descending: Bool = false) throws -> Query {
        var predicates = self.predicates
        predicates.append(.orderBy(try field.rpcFieldPath(), descending))
        return copy(predicates: predicates)
    }
}

extension Query {
    public func start(at values: [Any]) -> Query {
        var predicates = self.predicates
        predicates.append(.startAt(values))
        return copy(predicates: predicates)
    }

    public func start(after values: [Any]) -> Query {
        var predicates = self.predicates
        predicates.append(.startAfter(values))
        return copy(predicates: predicates)
    }

    public func end(at values: [Any]) -> Query {
        var predicates = self.predicates
        predicates.append(.endAt(values))
        return copy(predicates: predicates)
    }

    public func end(before values: [Any]) -> Query {
        var predicates = self.predicates
        predicates.append(.endBefore(values))
        return copy(predicates: predicates)
    }
}
