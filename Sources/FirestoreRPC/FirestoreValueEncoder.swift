import FirestoreCore
import FirestoreProtobuf

package struct FirestoreValueEncoder {
    package static func validateDocumentData(_ data: [String: Any], allowsDelete: Bool) throws {
        try validateDictionary(
            data,
            path: nil,
            allowsDelete: allowsDelete,
            allowsTransforms: true,
            isNestedInArray: false
        )
    }

    package static func encodeValue(_ value: Any, path: String) throws -> Google_Firestore_V1_Value {
        try validateValue(
            value,
            path: path,
            allowsDelete: false,
            allowsTransforms: false,
            isArrayElement: false,
            isNestedInArray: false
        )
        return try makeValue(value, path: path, isArrayElement: false)
    }

    package static func encodeQueryMembershipArray(
        _ values: [Any],
        path: String
    ) throws -> Google_Firestore_V1_Value {
        for (index, value) in values.enumerated() {
            try validateValue(
                value,
                path: "\(path)[\(index)]",
                allowsDelete: false,
                allowsTransforms: false,
                isArrayElement: false,
                isNestedInArray: false
            )
        }

        let encodedValues = try values.enumerated().map { index, value in
            try makeValue(value, path: "\(path)[\(index)]", isArrayElement: false)
        }
        return Google_Firestore_V1_Value.with {
            $0.arrayValue = Google_Firestore_V1_ArrayValue.with {
                $0.values = encodedValues
            }
        }
    }

    package static func encodeDocumentValue(
        _ value: Any,
        path: String,
        isArrayElement: Bool = false
    ) throws -> Google_Firestore_V1_Value? {
        if value is FieldValue {
            return nil
        }
        return try makeValue(value, path: path, isArrayElement: isArrayElement)
    }

    package static func encodeTransformArrayElements(
        _ elements: [Any],
        path: String
    ) throws -> [Google_Firestore_V1_Value] {
        try validateArray(
            elements,
            path: path,
            allowsDelete: false,
            allowsTransforms: false,
            isNestedInArray: true
        )
        return try elements.enumerated().map { index, value in
            try makeValue(value, path: "\(path)[\(index)]", isArrayElement: true)
        }
    }
}
