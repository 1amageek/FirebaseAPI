import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

extension FirestoreValueEncoder {
    static func makeValue(
        _ value: Any,
        path: String,
        isArrayElement: Bool
    ) throws -> Google_Firestore_V1_Value {
        var firestoreValue = Google_Firestore_V1_Value()

        if let vector = value as? FirestoreVector {
            if isArrayElement {
                throw FirestoreError.invalidFieldValue("FirestoreVector values cannot be used inside arrays at '\(path)'.")
            }
            return try encodeVector(vector, path: path)
        } else if let intValue = value as? Int {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? Int8 {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? Int16 {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? Int32 {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? Int64 {
            firestoreValue.integerValue = intValue
        } else if let intValue = value as? UInt {
            guard intValue <= UInt(Int64.max) else {
                throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Firestore Int64 range.")
            }
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? UInt8 {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? UInt16 {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? UInt32 {
            firestoreValue.integerValue = Int64(intValue)
        } else if let intValue = value as? UInt64 {
            guard intValue <= UInt64(Int64.max) else {
                throw FirestoreError.invalidFieldValue("Unsigned integer at '\(path)' exceeds Firestore Int64 range.")
            }
            firestoreValue.integerValue = Int64(intValue)
        } else if let boolValue = value as? Bool {
            firestoreValue.booleanValue = boolValue
        } else if let floatValue = value as? Float {
            firestoreValue.doubleValue = Double(floatValue)
        } else if let doubleValue = value as? Double {
            firestoreValue.doubleValue = doubleValue
        } else if let stringValue = value as? String {
            firestoreValue.stringValue = stringValue
        } else if let dataValue = value as? Data {
            firestoreValue.bytesValue = dataValue
        } else if let referenceValue = value as? DocumentReference {
            firestoreValue.referenceValue = referenceValue.name
        } else if let timestampValue = value as? Timestamp {
            firestoreValue.timestampValue = Google_Protobuf_Timestamp.with {
                $0.seconds = timestampValue.seconds
                $0.nanos = timestampValue.nanos
            }
        } else if let dateValue = value as? Date {
            firestoreValue.timestampValue = dateValue.firestoreTimestamp
        } else if let geoPointValue = value as? GeoPoint {
            firestoreValue.geoPointValue = Google_Type_LatLng.with {
                $0.latitude = geoPointValue.latitude
                $0.longitude = geoPointValue.longitude
            }
        } else if value is NSNull {
            firestoreValue.nullValue = .nullValue
        } else if let arrayValue = value as? [Any] {
            if isArrayElement {
                throw FirestoreError.invalidFieldValue("Arrays cannot directly contain arrays at '\(path)'.")
            }
            let encodedElements = try encodeArrayElements(arrayValue, path: path)
            firestoreValue.arrayValue = Google_Firestore_V1_ArrayValue.with {
                $0.values = encodedElements
            }
        } else if let mapValue = value as? [String: Any] {
            let encodedFields = try encodeMapFields(mapValue, path: path)
            firestoreValue.mapValue = Google_Firestore_V1_MapValue.with {
                $0.fields = encodedFields
            }
        } else {
            throw FirestoreError.invalidFieldValue("Unsupported Firestore value type \(type(of: value)) at '\(path)'.")
        }

        return firestoreValue
    }

    private static func encodeArrayElements(
        _ elements: [Any],
        path: String
    ) throws -> [Google_Firestore_V1_Value] {
        var values: [Google_Firestore_V1_Value] = []
        for (index, element) in elements.enumerated() {
            let value = try makeValue(element, path: "\(path)[\(index)]", isArrayElement: true)
            values.append(value)
        }
        return values
    }

    private static func encodeMapFields(
        _ map: [String: Any],
        path: String
    ) throws -> [String: Google_Firestore_V1_Value] {
        var fields: [String: Google_Firestore_V1_Value] = [:]
        for (key, value) in map {
            guard !(value is FieldValue) else {
                continue
            }
            try FirestoreFieldPath.validateDocumentFieldName(key)
            let fieldPath = "\(path).\(key)"
            fields[key] = try makeValue(value, path: fieldPath, isArrayElement: false)
        }
        return fields
    }
}

private extension Date {
    var firestoreTimestamp: Google_Protobuf_Timestamp {
        let seconds = floor(timeIntervalSince1970)
        let nanos = (timeIntervalSince1970 - seconds) * 1_000_000_000
        return Google_Protobuf_Timestamp.with {
            $0.seconds = Int64(seconds)
            $0.nanos = Int32(nanos)
        }
    }
}
