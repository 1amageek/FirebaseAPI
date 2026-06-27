import Foundation

public struct Filter {
    package let predicate: QueryPredicate

    package init(predicate: QueryPredicate) {
        self.predicate = predicate
    }

    public static func filter(whereField field: String, isEqualTo value: Any) -> Filter {
        Filter(predicate: .isEqualTo(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, isEqualTo value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, isEqualTo: value))
    }

    public static func filter(whereField field: String, isNotEqualTo value: Any) -> Filter {
        Filter(predicate: .isNotEqualTo(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, isNotEqualTo value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, isNotEqualTo: value))
    }

    public static func filter(whereField field: String, isLessThan value: Any) -> Filter {
        Filter(predicate: .isLessThan(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, isLessThan value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, isLessThan: value))
    }

    public static func filter(whereField field: String, isLessThanOrEqualTo value: Any) -> Filter {
        Filter(predicate: .isLessThanOrEqualTo(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, isLessThanOrEqualTo value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, isLessThanOrEqualTo: value))
    }

    public static func filter(whereField field: String, isGreaterThan value: Any) -> Filter {
        Filter(predicate: .isGreaterThan(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, isGreaterThan value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, isGreaterThan: value))
    }

    public static func filter(whereField field: String, isGreaterThanOrEqualTo value: Any) -> Filter {
        Filter(predicate: .isGreaterThanOrEqualTo(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, isGreaterThanOrEqualTo value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, isGreaterThanOrEqualTo: value))
    }

    public static func filter(whereField field: String, arrayContains value: Any) -> Filter {
        Filter(predicate: .arrayContains(field, value))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, arrayContains value: Any) throws -> Filter {
        Filter(predicate: try .field(fieldPath, arrayContains: value))
    }

    public static func filter(whereField field: String, arrayContainsAny values: [Any]) -> Filter {
        Filter(predicate: .arrayContainsAny(field, values))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, arrayContainsAny values: [Any]) throws -> Filter {
        Filter(predicate: try .field(fieldPath, arrayContainsAny: values))
    }

    public static func filter(whereField field: String, in values: [Any]) -> Filter {
        Filter(predicate: .isIn(field, values))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, in values: [Any]) throws -> Filter {
        Filter(predicate: try .field(fieldPath, in: values))
    }

    public static func filter(whereField field: String, notIn values: [Any]) -> Filter {
        Filter(predicate: .isNotIn(field, values))
    }

    public static func filter(whereFieldPath fieldPath: FieldPath, notIn values: [Any]) throws -> Filter {
        Filter(predicate: try .field(fieldPath, notIn: values))
    }

    public static func orFilter(with filters: [Filter]) -> Filter {
        Filter(predicate: .or(filters.map(\.predicate)))
    }

    public static func andFilter(with filters: [Filter]) -> Filter {
        Filter(predicate: .and(filters.map(\.predicate)))
    }
}
