public indirect enum FirestoreEmbeddedFilter: Equatable, Sendable {
    case field(FirestoreEmbeddedFieldFilter)
    case and([FirestoreEmbeddedFilter])
    case or([FirestoreEmbeddedFilter])

    public static func field(
        _ path: String,
        _ op: FirestoreEmbeddedFieldOperator,
        _ value: FirestoreEmbeddedValue
    ) throws(FirestoreEmbeddedError) -> FirestoreEmbeddedFilter {
        .field(try FirestoreEmbeddedFieldFilter(fieldPath: path, op: op, value: value))
    }

    public static func all(_ filters: [FirestoreEmbeddedFilter]) throws(FirestoreEmbeddedError) -> FirestoreEmbeddedFilter {
        guard !filters.isEmpty else {
            throw FirestoreEmbeddedError.invalidValue("AND filter requires at least one child filter.")
        }
        return .and(filters)
    }

    public static func any(_ filters: [FirestoreEmbeddedFilter]) throws(FirestoreEmbeddedError) -> FirestoreEmbeddedFilter {
        guard !filters.isEmpty else {
            throw FirestoreEmbeddedError.invalidValue("OR filter requires at least one child filter.")
        }
        return .or(filters)
    }
}

public struct FirestoreEmbeddedFieldFilter: Equatable, Sendable {
    public let fieldPath: String
    public let op: FirestoreEmbeddedFieldOperator
    public let value: FirestoreEmbeddedValue

    public init(
        fieldPath: String,
        op: FirestoreEmbeddedFieldOperator,
        value: FirestoreEmbeddedValue
    ) throws(FirestoreEmbeddedError) {
        let normalizedPath = fieldPath.firestoreEmbeddedTrimmedSlashes()
        guard !normalizedPath.isEmpty else {
            throw FirestoreEmbeddedError.invalidValue("Field path must not be empty.")
        }
        self.fieldPath = normalizedPath
        self.op = op
        self.value = value
    }
}

public enum FirestoreEmbeddedFieldOperator: String, Equatable, Sendable {
    case equal
    case notEqual
    case lessThan
    case lessThanOrEqual
    case greaterThan
    case greaterThanOrEqual
    case arrayContains
    case `in`
    case arrayContainsAny
    case notIn
}
