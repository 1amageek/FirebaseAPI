import Foundation

public protocol FirestoreQuerySource {
    func whereFilter(_ filter: Filter) -> Query

    func limit(to value: Int) -> Query
    func limit(toLast value: Int) -> Query
    func order(by field: String, descending: Bool) -> Query
    func order(by field: FieldPath, descending: Bool) throws -> Query
    func start(at values: [Any]) -> Query
    func start(after values: [Any]) -> Query
    func end(at values: [Any]) -> Query
    func end(before values: [Any]) -> Query
    func start(atDocument snapshot: DocumentSnapshot) throws -> Query
    func start(afterDocument snapshot: DocumentSnapshot) throws -> Query
    func end(atDocument snapshot: DocumentSnapshot) throws -> Query
    func end(beforeDocument snapshot: DocumentSnapshot) throws -> Query
    func start(atDocument snapshot: QueryDocumentSnapshot) throws -> Query
    func start(afterDocument snapshot: QueryDocumentSnapshot) throws -> Query
    func end(atDocument snapshot: QueryDocumentSnapshot) throws -> Query
    func end(beforeDocument snapshot: QueryDocumentSnapshot) throws -> Query
}

extension Query: FirestoreQuerySource {}
extension CollectionReference: FirestoreQuerySource {}
extension CollectionGroup: FirestoreQuerySource {}

public extension FirestoreQuerySource {
    func whereField(_ field: String, isEqualTo value: Any) -> Query {
        whereFilter(.filter(whereField: field, isEqualTo: value))
    }

    func whereField(_ field: FieldPath, isEqualTo value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, isEqualTo: value))
    }

    func whereField(_ field: String, isNotEqualTo value: Any) -> Query {
        whereFilter(.filter(whereField: field, isNotEqualTo: value))
    }

    func whereField(_ field: FieldPath, isNotEqualTo value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, isNotEqualTo: value))
    }

    func whereField(_ field: String, isLessThan value: Any) -> Query {
        whereFilter(.filter(whereField: field, isLessThan: value))
    }

    func whereField(_ field: FieldPath, isLessThan value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, isLessThan: value))
    }

    func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> Query {
        whereFilter(.filter(whereField: field, isLessThanOrEqualTo: value))
    }

    func whereField(_ field: FieldPath, isLessThanOrEqualTo value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, isLessThanOrEqualTo: value))
    }

    func whereField(_ field: String, isGreaterThan value: Any) -> Query {
        whereFilter(.filter(whereField: field, isGreaterThan: value))
    }

    func whereField(_ field: FieldPath, isGreaterThan value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, isGreaterThan: value))
    }

    func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> Query {
        whereFilter(.filter(whereField: field, isGreaterThanOrEqualTo: value))
    }

    func whereField(_ field: FieldPath, isGreaterThanOrEqualTo value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, isGreaterThanOrEqualTo: value))
    }

    func whereField(_ field: String, arrayContains value: Any) -> Query {
        whereFilter(.filter(whereField: field, arrayContains: value))
    }

    func whereField(_ field: FieldPath, arrayContains value: Any) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, arrayContains: value))
    }

    func whereField(_ field: String, arrayContainsAny value: [Any]) -> Query {
        whereFilter(.filter(whereField: field, arrayContainsAny: value))
    }

    func whereField(_ field: FieldPath, arrayContainsAny value: [Any]) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, arrayContainsAny: value))
    }

    func whereField(_ field: String, in value: [Any]) -> Query {
        whereFilter(.filter(whereField: field, in: value))
    }

    func whereField(_ field: FieldPath, in value: [Any]) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, in: value))
    }

    func whereField(_ field: String, notIn value: [Any]) -> Query {
        whereFilter(.filter(whereField: field, notIn: value))
    }

    func whereField(_ field: FieldPath, notIn value: [Any]) throws -> Query {
        try whereFilter(.filter(whereFieldPath: field, notIn: value))
    }

    func or(_ filters: [Filter]) -> Query {
        whereFilter(.orFilter(with: filters))
    }

    func and(_ filters: [Filter]) -> Query {
        whereFilter(.andFilter(with: filters))
    }
}
