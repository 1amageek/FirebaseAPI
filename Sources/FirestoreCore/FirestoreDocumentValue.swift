import Foundation

package enum FirestoreDocumentValue: Sendable {
    case null
    case boolean(Bool)
    case integer(Int)
    case double(Double)
    case timestamp(Timestamp)
    case string(String)
    case bytes(Data)
    case reference(DocumentReference)
    case geoPoint(GeoPoint)
    case array([FirestoreDocumentValue])
    case map([String: FirestoreDocumentValue])

    package var anyValue: Any {
        switch self {
        case .null:
            return NSNull()
        case .boolean(let value):
            return value
        case .integer(let value):
            return value
        case .double(let value):
            return value
        case .timestamp(let value):
            return value
        case .string(let value):
            return value
        case .bytes(let value):
            return value
        case .reference(let value):
            return value
        case .geoPoint(let value):
            return value
        case .array(let values):
            return values.map(\.anyValue)
        case .map(let values):
            return values.mapValues(\.anyValue)
        }
    }

    package static func anyValue(
        in fields: [String: FirestoreDocumentValue]?,
        fieldPath: String,
        serverTimestampBehavior: ServerTimestampBehavior
    ) throws -> Any? {
        guard let fields else {
            return nil
        }
        let segments = try FirestoreFieldPath.split(fieldPath)
        return value(in: fields, segments: segments)?.anyValue
    }

    package static func anyValue(
        in fields: [String: FirestoreDocumentValue]?,
        fieldPath: FieldPath,
        serverTimestampBehavior: ServerTimestampBehavior
    ) throws -> Any? {
        try anyValue(
            in: fields,
            fieldPath: fieldPath.rpcFieldPath(),
            serverTimestampBehavior: serverTimestampBehavior
        )
    }

    private static func value(
        in fields: [String: FirestoreDocumentValue],
        segments: [String]
    ) -> FirestoreDocumentValue? {
        guard let firstSegment = segments.first else {
            return nil
        }
        var currentValue = fields[firstSegment]
        for segment in segments.dropFirst() {
            guard case .map(let fields)? = currentValue else {
                return nil
            }
            currentValue = fields[segment]
        }
        return currentValue
    }
}

extension FirestoreDocumentValue {
    package static func fields(from data: [String: Any]) throws -> [String: FirestoreDocumentValue] {
        var fields: [String: FirestoreDocumentValue] = [:]
        for (key, value) in data {
            try FirestoreFieldPath.validateDocumentFieldName(key)
            fields[key] = try makeValue(from: value, path: key, isArrayElement: false)
        }
        return fields
    }

    private static func mapFields(from data: [String: Any], path: String) throws -> [String: FirestoreDocumentValue] {
        var fields: [String: FirestoreDocumentValue] = [:]
        for (key, value) in data {
            try FirestoreFieldPath.validateDocumentFieldName(key)
            fields[key] = try makeValue(from: value, path: "\(path).\(key)", isArrayElement: false)
        }
        return fields
    }

    private static func makeValue(
        from value: Any,
        path: String,
        isArrayElement: Bool
    ) throws -> FirestoreDocumentValue {
        if let value = value as? FirestoreDocumentValue {
            return value
        }
        if value is FieldValue {
            throw FirestoreError.invalidFieldValue("FieldValue sentinels cannot be used in snapshot data at '\(path)'.")
        }
        if let vector = value as? FirestoreVector {
            if isArrayElement {
                throw FirestoreError.invalidFieldValue("FirestoreVector values cannot be used inside arrays at '\(path)'.")
            }
            try validateVector(vector, path: path)
            return .array(vector.values.map { .double($0) })
        }

        switch value {
        case is NSNull:
            return .null
        case let value as Bool:
            return .boolean(value)
        case let value as Int:
            return .integer(value)
        case let value as Int8:
            return .integer(Int(value))
        case let value as Int16:
            return .integer(Int(value))
        case let value as Int32:
            return .integer(Int(value))
        case let value as Int64:
            guard let converted = Int(exactly: value) else {
                throw FirestoreError.invalidFieldValue("Integer at '\(path)' exceeds Swift Int range.")
            }
            return .integer(converted)
        case let value as UInt:
            guard let converted = Int(exactly: value) else {
                throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Swift Int range.")
            }
            return .integer(converted)
        case let value as UInt8:
            return .integer(Int(value))
        case let value as UInt16:
            return .integer(Int(value))
        case let value as UInt32:
            guard let converted = Int(exactly: value) else {
                throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Swift Int range.")
            }
            return .integer(converted)
        case let value as UInt64:
            guard let converted = Int(exactly: value) else {
                throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Swift Int range.")
            }
            return .integer(converted)
        case let value as Float:
            return .double(Double(value))
        case let value as Double:
            return .double(value)
        case let value as Decimal:
            return .double(Double(truncating: NSDecimalNumber(decimal: value)))
        case let value as String:
            return .string(value)
        case let value as URL:
            return .string(value.absoluteString)
        case let value as Data:
            return .bytes(value)
        case let value as DocumentReference:
            return .reference(value)
        case let value as Timestamp:
            return .timestamp(value)
        case let value as Date:
            return .timestamp(Timestamp(value))
        case let value as GeoPoint:
            return .geoPoint(value)
        case let value as [Any]:
            if isArrayElement {
                throw FirestoreError.invalidFieldValue("Arrays cannot directly contain arrays at '\(path)'.")
            }
            let values = try value.enumerated().map { index, element in
                try makeValue(from: element, path: "\(path)[\(index)]", isArrayElement: true)
            }
            return .array(values)
        case let value as [String: Any]:
            return .map(try mapFields(from: value, path: path))
        default:
            throw FirestoreError.invalidFieldValue("Unsupported Firestore snapshot value type \(type(of: value)) at '\(path)'.")
        }
    }

    private static func validateVector(_ vector: FirestoreVector, path: String) throws {
        guard !vector.values.isEmpty else {
            throw FirestoreError.invalidFieldValue("FirestoreVector at '\(path)' must contain at least one dimension.")
        }
        guard vector.values.count <= 2_048 else {
            throw FirestoreError.invalidFieldValue("FirestoreVector at '\(path)' exceeds 2,048 dimensions.")
        }
    }
}
