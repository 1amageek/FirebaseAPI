import Foundation

extension CollectionReference {
    public func whereFilter(_ filter: Filter) -> Query {
        makeQuery(predicates: [filter.predicate])
    }

    public func limit(to value: Int) -> Query {
        makeQuery(predicates: [.limitTo(value)])
    }

    public func limit(toLast value: Int) -> Query {
        makeQuery(predicates: [.limitToLast(value)])
    }

    public func order(by field: String, descending value: Bool) -> Query {
        makeQuery(predicates: [.orderBy(field, value)])
    }

    public func order(by field: FieldPath, descending value: Bool = false) throws -> Query {
        makeQuery(predicates: [.orderBy(try field.rpcFieldPath(), value)])
    }

    public func start(at values: [Any]) -> Query {
        makeQuery(predicates: [.startAt(values)])
    }

    public func start(after values: [Any]) -> Query {
        makeQuery(predicates: [.startAfter(values)])
    }

    public func end(at values: [Any]) -> Query {
        makeQuery(predicates: [.endAt(values)])
    }

    public func end(before values: [Any]) -> Query {
        makeQuery(predicates: [.endBefore(values)])
    }

    public func start(atDocument snapshot: DocumentSnapshot) throws -> Query {
        try toQuery().start(atDocument: snapshot)
    }

    public func start(afterDocument snapshot: DocumentSnapshot) throws -> Query {
        try toQuery().start(afterDocument: snapshot)
    }

    public func end(atDocument snapshot: DocumentSnapshot) throws -> Query {
        try toQuery().end(atDocument: snapshot)
    }

    public func end(beforeDocument snapshot: DocumentSnapshot) throws -> Query {
        try toQuery().end(beforeDocument: snapshot)
    }

    public func start(atDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try toQuery().start(atDocument: snapshot)
    }

    public func start(afterDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try toQuery().start(afterDocument: snapshot)
    }

    public func end(atDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try toQuery().end(atDocument: snapshot)
    }

    public func end(beforeDocument snapshot: QueryDocumentSnapshot) throws -> Query {
        try toQuery().end(beforeDocument: snapshot)
    }
}
