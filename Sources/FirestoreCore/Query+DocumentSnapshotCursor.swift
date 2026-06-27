import Foundation

private enum DocumentSnapshotCursor {
    case startAt
    case startAfter
    case endAt
    case endBefore

    func query(from query: Query, values: [Any]) -> Query {
        switch self {
        case .startAt:
            return query.start(at: values)
        case .startAfter:
            return query.start(after: values)
        case .endAt:
            return query.end(at: values)
        case .endBefore:
            return query.end(before: values)
        }
    }
}

private struct DocumentSnapshotCursorOrder {
    let field: String
    let descending: Bool
}

private protocol DocumentSnapshotCursorSource {
    var cursorDocumentReference: DocumentReference { get }
    var cursorExists: Bool { get }
    func cursorValue(forOrderField field: String) -> Any?
}

extension DocumentSnapshot: DocumentSnapshotCursorSource {
    fileprivate var cursorDocumentReference: DocumentReference { documentReference }
    fileprivate var cursorExists: Bool { exists }

    fileprivate func cursorValue(forOrderField field: String) -> Any? {
        if field == "__name__" {
            return documentReference
        }
        return get(field)
    }
}

extension QueryDocumentSnapshot: DocumentSnapshotCursorSource {
    fileprivate var cursorDocumentReference: DocumentReference { documentReference }
    fileprivate var cursorExists: Bool { true }

    fileprivate func cursorValue(forOrderField field: String) -> Any? {
        if field == "__name__" {
            return documentReference
        }
        return get(field)
    }
}

extension Query {
    public func start(atDocument snapshot: DocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.startAt, snapshot: snapshot)
    }

    public func start(afterDocument snapshot: DocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.startAfter, snapshot: snapshot)
    }

    public func end(atDocument snapshot: DocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.endAt, snapshot: snapshot)
    }

    public func end(beforeDocument snapshot: DocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.endBefore, snapshot: snapshot)
    }

    public func start(atDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.startAt, snapshot: snapshot)
    }

    public func start(afterDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.startAfter, snapshot: snapshot)
    }

    public func end(atDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.endAt, snapshot: snapshot)
    }

    public func end(beforeDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try applyingDocumentSnapshotCursor(.endBefore, snapshot: snapshot)
    }

    private func applyingDocumentSnapshotCursor(
        _ cursor: DocumentSnapshotCursor,
        snapshot: some DocumentSnapshotCursorSource
    ) throws -> Query {
        try validateCursorDatabase(snapshot)
        let orders = normalizedCursorOrders()
        let values = try makeCursorValues(from: snapshot, orders: orders)
        let query = queryWithImplicitCursorOrders(orders)
        return cursor.query(from: query, values: values)
    }

    private func makeCursorValues(
        from snapshot: some DocumentSnapshotCursorSource,
        orders: [DocumentSnapshotCursorOrder]
    ) throws -> [Any] {
        guard snapshot.cursorExists else {
            throw FirestoreError.invalidQuery("Document snapshot cursors require an existing document snapshot.")
        }

        return try orders.map { order in
            guard let value = snapshot.cursorValue(forOrderField: order.field) else {
                throw FirestoreError.invalidQuery("Document snapshot cursor is missing ordered field '\(order.field)'.")
            }
            return value
        }
    }

    private func normalizedCursorOrders() -> [DocumentSnapshotCursorOrder] {
        var orders: [DocumentSnapshotCursorOrder] = []
        var orderedFields = Set<String>()
        for predicate in predicates {
            if case .orderBy(let field, let descending) = predicate {
                orders.append(DocumentSnapshotCursorOrder(field: field, descending: descending))
                orderedFields.insert(field)
            }
        }

        let implicitDescending = orders.last?.descending ?? false
        for field in implicitInequalityOrderFields(excluding: orderedFields) {
            orders.append(DocumentSnapshotCursorOrder(field: field, descending: implicitDescending))
            orderedFields.insert(field)
        }
        if !orderedFields.contains("__name__") {
            orders.append(DocumentSnapshotCursorOrder(field: "__name__", descending: implicitDescending))
        }
        return orders
    }

    private func queryWithImplicitCursorOrders(
        _ normalizedOrders: [DocumentSnapshotCursorOrder]
    ) -> Query {
        let existingOrderCount = predicates.filter { predicate in
            if case .orderBy = predicate {
                return true
            }
            return false
        }.count
        guard normalizedOrders.count > existingOrderCount else {
            return self
        }

        let implicitOrders = normalizedOrders.dropFirst(existingOrderCount)
        var predicates = self.predicates
        predicates.append(contentsOf: implicitOrders.map { .orderBy($0.field, $0.descending) })
        return copy(predicates: predicates)
    }

    private func implicitInequalityOrderFields(excluding orderedFields: Set<String>) -> [String] {
        var fields = Set<String>()
        for predicate in predicates {
            for field in predicate.implicitInequalityOrderFields {
                if field != "__name__" && !orderedFields.contains(field) {
                    fields.insert(field)
                }
            }
        }
        return fields.sorted()
    }
}

private extension QueryPredicate {
    var implicitInequalityOrderFields: [String] {
        switch self {
        case .isNotEqualTo(let field, _),
             .isNotIn(let field, _),
             .isLessThan(let field, _),
             .isGreaterThan(let field, _),
             .isLessThanOrEqualTo(let field, _),
             .isGreaterThanOrEqualTo(let field, _):
            return [field]

        case .isNotEqualToDocumentID,
             .isNotInDocumentID,
             .isLessThanDocumentID,
             .isGreaterThanDocumentID,
             .isLessThanOrEqualToDocumentID,
             .isGreaterThanOrEqualToDocumentID:
            return ["__name__"]

        case .or(let predicates),
             .and(let predicates):
            return predicates.flatMap(\.implicitInequalityOrderFields)

        default:
            return []
        }
    }
}

private extension Query {
    private func validateCursorDatabase(
        _ snapshot: some DocumentSnapshotCursorSource
    ) throws {
        let snapshotDatabase = snapshot.cursorDocumentReference.database
        guard snapshotDatabase == database else {
            throw FirestoreError.databaseMismatch(
                expected: database.database,
                actual: snapshotDatabase.database
            )
        }
    }
}
