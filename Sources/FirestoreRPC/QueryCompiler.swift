import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

package struct RunQueryPlan {
    package let request: Google_Firestore_V1_RunQueryRequest
    package let requiresResultOrderReversal: Bool
}

private struct StructuredQueryPlan {
    package let query: Google_Firestore_V1_StructuredQuery
    package let requiresResultOrderReversal: Bool
    package let userVisibleSortOrders: [QuerySortOrder]
}

struct QueryOrder {
    let field: String
    let descending: Bool
}

struct QueryLimit {
    let count: Int
    let isToLast: Bool
}

struct QueryCursor {
    let values: [Any]
    let before: Bool
}

package struct QueryCompiler {
    package let query: Query

    package init(query: Query) {
        self.query = query
    }

    package func makeStructuredQuery() throws -> Google_Firestore_V1_StructuredQuery {
        try makeStructuredQueryPlan().query
    }

    package func makeUserVisibleSortOrders() throws -> [QuerySortOrder] {
        try makeStructuredQueryPlan().userVisibleSortOrders
    }

    package func makeRunQueryPlan(
        transactionID: Data? = nil,
        explainOptions: FirestoreExplainOptions? = nil
    ) throws -> RunQueryPlan {
        let structuredQueryPlan = try makeStructuredQueryPlan()
        let request = Google_Firestore_V1_RunQueryRequest.with {
            $0.parent = query.name
            $0.structuredQuery = structuredQueryPlan.query
            if let transactionID {
                $0.transaction = transactionID
            }
            if let explainOptions {
                $0.explainOptions = makeExplainOptions(explainOptions)
            }
        }
        return RunQueryPlan(
            request: request,
            requiresResultOrderReversal: structuredQueryPlan.requiresResultOrderReversal
        )
    }

    private func makeStructuredQueryPlan() throws -> StructuredQueryPlan {
        var structuredQuery = Google_Firestore_V1_StructuredQuery()
        structuredQuery.from = [
            Google_Firestore_V1_StructuredQuery.CollectionSelector.with {
                $0.collectionID = query.collectionID
                $0.allDescendants = query.allDescendants
            }
        ]

        var orders: [QueryOrder] = []
        var limit: QueryLimit?
        var startCursor: QueryCursor?
        var endCursor: QueryCursor?
        var findNearest: FirestoreFindNearestQuery?

        for predicate in query.predicates {
            try applyNonFilter(
                predicate,
                orders: &orders,
                limit: &limit,
                startCursor: &startCursor,
                endCursor: &endCursor,
                findNearest: &findNearest
            )
        }

        try QueryConstraintValidator.validate(
            predicates: query.predicates,
            orderFields: orders.map(\.field),
            parentPath: query.parentPath
        )

        let predicateFilterCompiler = QueryPredicateFilterCompiler(
            database: query.database,
            parentPath: query.parentPath,
            collectionID: query.collectionID,
            allDescendants: query.allDescendants
        )
        let filters = try query.predicates.compactMap(predicateFilterCompiler.makeFilter)

        if filters.count == 1, let filter = filters.first {
            structuredQuery.where = filter
        } else if !filters.isEmpty {
            structuredQuery.where = Google_Firestore_V1_StructuredQuery.Filter.with {
                $0.compositeFilter = Google_Firestore_V1_StructuredQuery.CompositeFilter.with {
                    $0.op = .and
                    $0.filters = filters
                }
            }
        }

        if let limit, findNearest != nil {
            if limit.isToLast {
                throw FirestoreError.invalidQuery("findNearest cannot be combined with limitToLast.")
            }
            throw FirestoreError.invalidQuery("findNearest limit must be provided through findNearest(...), not Query.limit(to:).")
        }

        let requiresResultOrderReversal = limit?.isToLast == true
        if requiresResultOrderReversal && orders.isEmpty {
            throw FirestoreError.invalidQuery("limitToLast requires at least one orderBy clause.")
        }

        let userVisibleSortOrders = try orders.map(makeSortOrder)
        let rpcOrders = requiresResultOrderReversal ? userVisibleSortOrders.map(reversedOrder) : userVisibleSortOrders
        let rpcStartCursor = requiresResultOrderReversal ? endCursor.map(reversedCursorBoundary) : startCursor
        let rpcEndCursor = requiresResultOrderReversal ? startCursor.map(reversedCursorBoundary) : endCursor
        structuredQuery.orderBy = rpcOrders.map(makeOrder)

        if startCursor != nil || endCursor != nil, userVisibleSortOrders.isEmpty {
            throw FirestoreError.invalidQuery("Query cursors require at least one orderBy clause.")
        }
        if let rpcStartCursor {
            structuredQuery.startAt = try makeCursor(
                rpcStartCursor,
                orders: rpcOrders,
                label: "start cursor"
            )
        }
        if let rpcEndCursor {
            structuredQuery.endAt = try makeCursor(
                rpcEndCursor,
                orders: rpcOrders,
                label: "end cursor"
            )
        }

        if let limit {
            guard limit.count >= 0 else {
                throw FirestoreError.invalidQuery("Query limit must be greater than or equal to zero.")
            }
            guard limit.count <= Int(Int32.max) else {
                throw FirestoreError.invalidQuery("Query limit exceeds Int32 range.")
            }
            structuredQuery.limit = Google_Protobuf_Int32Value.with {
                $0.value = Int32(limit.count)
            }
        }
        if let findNearest {
            guard startCursor == nil && endCursor == nil else {
                throw FirestoreError.invalidQuery("findNearest cannot be combined with query cursors.")
            }
            structuredQuery.findNearest = try makeFindNearest(findNearest)
        }

        return StructuredQueryPlan(
            query: structuredQuery,
            requiresResultOrderReversal: requiresResultOrderReversal,
            userVisibleSortOrders: userVisibleSortOrders
        )
    }

    package func makeRunQueryRequest(
        transactionID: Data? = nil,
        explainOptions: FirestoreExplainOptions? = nil
    ) throws -> Google_Firestore_V1_RunQueryRequest {
        try makeRunQueryPlan(
            transactionID: transactionID,
            explainOptions: explainOptions
        ).request
    }

    func applyNonFilter(
        _ predicate: QueryPredicate,
        orders: inout [QueryOrder],
        limit: inout QueryLimit?,
        startCursor: inout QueryCursor?,
        endCursor: inout QueryCursor?,
        findNearest: inout FirestoreFindNearestQuery?
    ) throws {
        switch predicate {
        case .orderBy(let field, let descending):
            orders.append(QueryOrder(field: field, descending: descending))

        case .limitTo(let count):
            limit = QueryLimit(count: count, isToLast: false)

        case .limitToLast(let count):
            limit = QueryLimit(count: count, isToLast: true)

        case .startAt(let values):
            startCursor = QueryCursor(values: values, before: true)

        case .startAfter(let values):
            startCursor = QueryCursor(values: values, before: false)

        case .endAt(let values):
            endCursor = QueryCursor(values: values, before: false)

        case .endBefore(let values):
            endCursor = QueryCursor(values: values, before: true)

        case .findNearest(let query):
            guard findNearest == nil else {
                throw FirestoreError.invalidQuery("Query supports at most one findNearest clause.")
            }
            findNearest = query

        default:
            break
        }
    }

    func makeOrder(_ order: QuerySortOrder) -> Google_Firestore_V1_StructuredQuery.Order {
        return Google_Firestore_V1_StructuredQuery.Order.with {
            $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                $0.fieldPath = order.fieldPath
            }
            $0.direction = order.descending ? .descending : .ascending
        }
    }

    func makeSortOrder(_ order: QueryOrder) throws -> QuerySortOrder {
        QuerySortOrder(
            fieldPath: try FirestoreFieldPath.normalize(order.field),
            descending: order.descending
        )
    }

    func reversedOrder(_ order: QuerySortOrder) -> QuerySortOrder {
        QuerySortOrder(fieldPath: order.fieldPath, descending: !order.descending)
    }

    func reversedCursorBoundary(_ cursor: QueryCursor) -> QueryCursor {
        QueryCursor(values: cursor.values, before: !cursor.before)
    }
}

extension Query {
    package func makeQuery() throws -> Google_Firestore_V1_StructuredQuery {
        try QueryCompiler(query: self).makeStructuredQuery()
    }
}
