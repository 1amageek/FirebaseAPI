import Foundation

public struct AggregateField: Hashable, Sendable {
    package enum Operation: String, Sendable {
        case count
        case sum
        case average
    }

    package let operation: Operation
    package let fieldPath: String?
    package let alias: String

    private init(operation: Operation, fieldPath: String?, alias: String?) {
        self.operation = operation
        self.fieldPath = fieldPath
        self.alias = alias ?? Self.defaultAlias(operation: operation, fieldPath: fieldPath)
    }

    public static func count(alias: String? = nil) -> AggregateField {
        AggregateField(operation: .count, fieldPath: nil, alias: alias)
    }

    public static func sum(_ field: String, alias: String? = nil) -> AggregateField {
        AggregateField(operation: .sum, fieldPath: field, alias: alias)
    }

    public static func sum(_ field: FieldPath, alias: String? = nil) throws -> AggregateField {
        AggregateField(operation: .sum, fieldPath: try field.rpcFieldPath(), alias: alias)
    }

    public static func average(_ field: String, alias: String? = nil) -> AggregateField {
        AggregateField(operation: .average, fieldPath: field, alias: alias)
    }

    public static func average(_ field: FieldPath, alias: String? = nil) throws -> AggregateField {
        AggregateField(operation: .average, fieldPath: try field.rpcFieldPath(), alias: alias)
    }

    private static func defaultAlias(operation: Operation, fieldPath: String?) -> String {
        guard let fieldPath else {
            return operation.rawValue
        }

        let sanitizedScalars = fieldPath.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "_"
        }
        let sanitized = String(sanitizedScalars).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        guard !sanitized.isEmpty else {
            return operation.rawValue
        }
        return "\(operation.rawValue)_\(sanitized)"
    }
}
