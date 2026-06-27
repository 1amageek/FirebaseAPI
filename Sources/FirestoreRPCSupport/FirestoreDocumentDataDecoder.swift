//
//  FirestoreDocumentDataDecoder.swift
//
//
//  Created on 2026/06/25.
//

import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct FirestoreDocumentDataDecoder {
    private let runtime: (any FirestoreReferenceRuntime)?

    package init(runtime: (any FirestoreReferenceRuntime)? = nil) {
        self.runtime = runtime
    }

    package func decode(document: Google_Firestore_V1_Document?) throws -> [String: FirestoreDocumentValue]? {
        guard let document else {
            return nil
        }
        return try decode(fields: document.fields)
    }

    package func decode(fields: [String: Google_Firestore_V1_Value]) throws -> [String: FirestoreDocumentValue] {
        var data: [String: FirestoreDocumentValue] = [:]
        for (key, value) in fields {
            if let decodedValue = try decode(value: value) {
                data[key] = decodedValue
            }
        }
        return data
    }

    private func decode(value: Google_Firestore_V1_Value) throws -> FirestoreDocumentValue? {
        switch value.valueType {
        case .nullValue:
            return .null
        case .booleanValue(let value):
            return .boolean(value)
        case .integerValue(let value):
            return .integer(Int(value))
        case .doubleValue(let value):
            return .double(value)
        case .timestampValue(let value):
            return .timestamp(Timestamp(seconds: value.seconds, nanos: value.nanos))
        case .stringValue(let value):
            return .string(value)
        case .bytesValue(let value):
            return .bytes(value)
        case .referenceValue(let value):
            return .reference(try makeDocumentReference(name: value))
        case .geoPointValue(let value):
            return .geoPoint(GeoPoint(latitude: value.latitude, longitude: value.longitude))
        case .arrayValue(let value):
            var values: [FirestoreDocumentValue] = []
            for element in value.values {
                if let decodedValue = try decode(value: element) {
                    values.append(decodedValue)
                }
            }
            return .array(values)
        case .mapValue(let value):
            return .map(try decode(fields: value.fields))
        case .fieldReferenceValue, .variableReferenceValue, .functionValue, .pipelineValue:
            return nil
        case .none:
            return nil
        }
    }

    private func makeDocumentReference(name: String) throws -> DocumentReference {
        let reference = try DocumentReference(name: name)
        guard let runtime, reference.database == runtime.runtimeDatabase else {
            return reference
        }
        return try DocumentReference(name: name, runtime: runtime)
    }
}
