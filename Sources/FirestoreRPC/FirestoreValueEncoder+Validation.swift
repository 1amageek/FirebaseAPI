import Foundation
import FirestoreCore

extension FirestoreValueEncoder {
    static func validateDictionary(
        _ dictionary: [String: Any],
        path: String?,
        allowsDelete: Bool,
        allowsTransforms: Bool,
        isNestedInArray: Bool
    ) throws {
        for (key, value) in dictionary {
            let fieldPath = path.map { "\($0).\(key)" } ?? key
            try validateValue(
                value,
                path: fieldPath,
                allowsDelete: allowsDelete,
                allowsTransforms: allowsTransforms,
                isArrayElement: false,
                isNestedInArray: isNestedInArray
            )
        }
    }

    static func validateArray(
        _ array: [Any],
        path: String,
        allowsDelete: Bool,
        allowsTransforms: Bool,
        isNestedInArray: Bool
    ) throws {
        for (index, value) in array.enumerated() {
            try validateValue(
                value,
                path: "\(path)[\(index)]",
                allowsDelete: allowsDelete,
                allowsTransforms: allowsTransforms,
                isArrayElement: true,
                isNestedInArray: isNestedInArray
            )
        }
    }

    static func validateValue(
        _ value: Any,
        path: String,
        allowsDelete: Bool,
        allowsTransforms: Bool,
        isArrayElement: Bool,
        isNestedInArray: Bool
    ) throws {
        if let fieldValue = value as? FieldValue {
            try validateSentinel(
                fieldValue,
                path: path,
                allowsDelete: allowsDelete,
                allowsTransforms: allowsTransforms,
                isNestedInArray: isNestedInArray
            )
        } else if let vector = value as? FirestoreVector {
            if isArrayElement {
                throw FirestoreError.invalidFieldValue("FirestoreVector values cannot be used inside arrays at '\(path)'.")
            }
            try validateVector(vector, path: path)
        } else if let array = value as? [Any] {
            if isArrayElement {
                throw FirestoreError.invalidFieldValue("Arrays cannot directly contain arrays at '\(path)'.")
            }
            try validateArray(
                array,
                path: path,
                allowsDelete: allowsDelete,
                allowsTransforms: allowsTransforms,
                isNestedInArray: true
            )
        } else if let dictionary = value as? [String: Any] {
            try validateDictionary(
                dictionary,
                path: path,
                allowsDelete: allowsDelete,
                allowsTransforms: allowsTransforms,
                isNestedInArray: isNestedInArray
            )
        } else {
            try validateScalarValue(value, path: path)
        }
    }

    private static func validateSentinel(
        _ fieldValue: FieldValue,
        path: String,
        allowsDelete: Bool,
        allowsTransforms: Bool,
        isNestedInArray: Bool
    ) throws {
        if isNestedInArray {
            throw FirestoreError.invalidFieldValue("FieldValue sentinels cannot be used inside arrays at '\(path)'.")
        }

        if !allowsTransforms {
            throw FirestoreError.invalidFieldValue("FieldValue sentinels cannot be used as Firestore values at '\(path)'.")
        }

        switch fieldValue {
        case .delete:
            if !allowsDelete {
                throw FirestoreError.invalidFieldValue("FieldValue.delete requires merge or update data at '\(path)'.")
            }
        case let .arrayUnion(elements), let .arrayRemove(elements):
            try validateArray(
                elements,
                path: path,
                allowsDelete: allowsDelete,
                allowsTransforms: false,
                isNestedInArray: true
            )
        case .serverTimestamp, .increment, .incrementInt64:
            break
        }
    }

    private static func validateScalarValue(_ value: Any, path: String) throws {
        if let intValue = value as? UInt, intValue > UInt(Int64.max) {
            throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Firestore Int64 range.")
        }
        if let intValue = value as? UInt64, intValue > UInt64(Int64.max) {
            throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Firestore Int64 range.")
        }
        if let vector = value as? FirestoreVector {
            try validateVector(vector, path: path)
            return
        }

        switch value {
        case is NSNull,
             is Int,
             is Int8,
             is Int16,
             is Int32,
             is Int64,
             is UInt,
             is UInt8,
             is UInt16,
             is UInt32,
             is UInt64,
             is Bool,
             is Float,
             is Double,
             is String,
             is Data,
             is DocumentReference,
             is Timestamp,
             is Date,
             is GeoPoint:
            return
        default:
            throw FirestoreError.invalidFieldValue("Unsupported Firestore value type \(type(of: value)) at '\(path)'.")
        }
    }
}
