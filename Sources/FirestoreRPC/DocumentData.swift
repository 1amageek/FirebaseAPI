//
//  DocumentData.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

package struct DocumentData {

    package var data: [String: Any]
    package var interpretsFieldPathKeys: Bool

    package var keys: [String] { Array(data.keys) }

    package init(data: [String : Any], interpretsFieldPathKeys: Bool = false) {
        self.data = data
        self.interpretsFieldPathKeys = interpretsFieldPathKeys
    }

    package func getFields(allowsDelete: Bool) throws -> [String: Google_Firestore_V1_Value] {
        try validateFieldKeys()
        try FirestoreValueEncoder.validateDocumentData(data, allowsDelete: allowsDelete)

        var fields: [String: Google_Firestore_V1_Value] = [:]
        for (key, value) in data {
            if let firestoreValue = try FirestoreValueEncoder.encodeDocumentValue(value, path: key) {
                if interpretsFieldPathKeys {
                    let segments = try FirestoreFieldPath.split(key)
                    DocumentData.setValue(firestoreValue, forPathSegments: segments, in: &fields)
                } else {
                    fields[key] = firestoreValue
                }
            }
        }
        return fields
    }

    package func mergeFieldPaths() throws -> [String] {
        try DocumentData.collectMergeFieldPaths(in: data).sorted()
    }

    package func updateFieldPaths() throws -> [String] {
        try data.compactMap { key, value in
            guard DocumentData.shouldIncludeInUpdateMask(value) else {
                return nil
            }
            return try FirestoreFieldPath.normalizeDocumentFieldPath(key)
        }
        .sorted()
    }

    package func transformFieldPathsExcludedFromUpdateMask() throws -> Set<String> {
        let fieldValues = try getFieldValues(in: data)
        let transformFieldPaths = fieldValues.compactMap { fieldPath, fieldValue in
            DocumentData.shouldIncludeInUpdateMask(fieldValue) ? nil : fieldPath
        }
        return Set(transformFieldPaths)
    }

    private static func setValue(
        _ value: Google_Firestore_V1_Value,
        forPathSegments segments: [String],
        in fields: inout [String: Google_Firestore_V1_Value]
    ) {
        guard let firstSegment = segments.first else {
            return
        }
        let remainingSegments = Array(segments.dropFirst())
        guard !remainingSegments.isEmpty else {
            fields[firstSegment] = value
            return
        }

        var existingValue = fields[firstSegment] ?? Google_Firestore_V1_Value()
        var mapFields = existingValue.mapValue.fields
        setValue(value, forPathSegments: remainingSegments, in: &mapFields)
        existingValue.mapValue = Google_Firestore_V1_MapValue.with {
            $0.fields = mapFields
        }
        fields[firstSegment] = existingValue
    }

    private static func collectMergeFieldPaths(
        in dictionary: [String: Any],
        prefixSegments: [String] = []
    ) throws -> [String] {
        var fieldPaths: [String] = []
        for (key, value) in dictionary {
            let segments = prefixSegments + [key]
            let fieldPath = try FirestoreFieldPath.encode(segments)

            if let fieldValue = value as? FieldValue {
                guard shouldIncludeInUpdateMask(fieldValue) else {
                    continue
                }
                fieldPaths.append(fieldPath)
            } else if let nestedDictionary = value as? [String: Any] {
                if nestedDictionary.isEmpty {
                    fieldPaths.append(fieldPath)
                } else {
                    let nestedFieldPaths = try collectMergeFieldPaths(
                        in: nestedDictionary,
                        prefixSegments: segments
                    )
                    fieldPaths.append(contentsOf: nestedFieldPaths)
                }
            } else {
                fieldPaths.append(fieldPath)
            }
        }
        return fieldPaths
    }

    private static func shouldIncludeInUpdateMask(_ value: Any) -> Bool {
        guard let fieldValue = value as? FieldValue else {
            return true
        }
        return shouldIncludeInUpdateMask(fieldValue)
    }

    private static func shouldIncludeInUpdateMask(_ fieldValue: FieldValue) -> Bool {
        switch fieldValue {
        case .delete:
            return true
        case .serverTimestamp, .arrayUnion, .arrayRemove, .increment, .incrementInt64:
            return false
        }
    }

    package func getFieldTransforms(
        documentPath: String,
        allowsDelete: Bool,
        allowedFieldPaths: Set<String>? = nil
    ) throws -> [Google_Firestore_V1_DocumentTransform.FieldTransform] {
        try validateFieldKeys()
        try FirestoreValueEncoder.validateDocumentData(data, allowsDelete: allowsDelete)
        let fieldValues = try getFieldValues(in: data)
        return try fieldValuesToFieldTransforms(
            documentPath: documentPath,
            fieldValues: fieldValues,
            allowedFieldPaths: allowedFieldPaths
        )
    }

    package func validateExplicitMergeFieldPaths(_ fieldPaths: [String]) throws {
        try FirestoreFieldPath.validateNoConflictingFieldPaths(
            fieldPaths,
            label: "mergeFields"
        )
        for fieldPath in fieldPaths {
            guard try containsValue(forDocumentFieldPath: fieldPath) else {
                throw FirestoreError.invalidFieldPath("mergeFields contains field path '\(fieldPath)' without a corresponding value in data.")
            }
        }
    }

    package func getFieldValues(
        in dictionary: [String: Any],
        prefixSegments: [String] = [],
        interpretsKeysAsFieldPaths: Bool? = nil
    ) throws -> [String: FieldValue] {
        let interpretsCurrentKeysAsFieldPaths = interpretsKeysAsFieldPaths ?? interpretsFieldPathKeys
        var fieldValues: [String: FieldValue] = [:]
        for (key, value) in dictionary {
            let keySegments = interpretsCurrentKeysAsFieldPaths
                ? try FirestoreFieldPath.splitDocumentFieldPath(key)
                : [key]
            let fullPathSegments = prefixSegments + keySegments
            let fullPath = try FirestoreFieldPath.encode(fullPathSegments)

            if let fieldValue = value as? FieldValue {
                fieldValues[fullPath] = fieldValue
            } else if let nestedDict = value as? [String: Any] {
                let nestedFieldValues = try getFieldValues(
                    in: nestedDict,
                    prefixSegments: fullPathSegments,
                    interpretsKeysAsFieldPaths: false
                )
                fieldValues.merge(nestedFieldValues) { _, new in new }
            }
        }
        return fieldValues
    }

    package func fieldValuesToFieldTransforms(
        documentPath: String,
        fieldValues: [String: FieldValue],
        allowedFieldPaths: Set<String>? = nil
    ) throws -> [Google_Firestore_V1_DocumentTransform.FieldTransform] {
        var fieldTransforms: [Google_Firestore_V1_DocumentTransform.FieldTransform] = []
        for (fieldPath, value) in fieldValues {
            if let allowedFieldPaths, !DocumentData.isFieldPath(fieldPath, coveredBy: allowedFieldPaths) {
                continue
            }
            var fieldTransform = Google_Firestore_V1_DocumentTransform.FieldTransform()
            fieldTransform.fieldPath = fieldPath
            switch value {
            case let .arrayUnion(elements):
                let values = try FirestoreValueEncoder.encodeTransformArrayElements(elements, path: fieldPath)
                fieldTransform.appendMissingElements = Google_Firestore_V1_ArrayValue.with {
                    $0.values = values
                }
            case let .arrayRemove(elements):
                let values = try FirestoreValueEncoder.encodeTransformArrayElements(elements, path: fieldPath)
                fieldTransform.removeAllFromArray = Google_Firestore_V1_ArrayValue.with {
                    $0.values = values
                }
            case let .increment(value):
                fieldTransform.increment = try FirestoreValueEncoder.encodeValue(value, path: fieldPath)
            case let .incrementInt64(value):
                fieldTransform.increment = try FirestoreValueEncoder.encodeValue(value, path: fieldPath)
            case .serverTimestamp:
                fieldTransform.setToServerValue = .requestTime
            case .delete:
                continue
            }

            fieldTransforms.append(fieldTransform)
        }
        return fieldTransforms
    }

    private func containsValue(forDocumentFieldPath fieldPath: String) throws -> Bool {
        let segments = try FirestoreFieldPath.splitDocumentFieldPath(fieldPath)
        return DocumentData.containsValue(in: data, segments: segments)
    }

    private static func containsValue(in dictionary: [String: Any], segments: [String]) -> Bool {
        guard let firstSegment = segments.first else {
            return false
        }
        guard let value = dictionary[firstSegment] else {
            return false
        }
        let remainingSegments = Array(segments.dropFirst())
        guard !remainingSegments.isEmpty else {
            return true
        }
        guard let nestedDictionary = value as? [String: Any] else {
            return false
        }
        return containsValue(in: nestedDictionary, segments: remainingSegments)
    }

    private static func isFieldPath(_ fieldPath: String, coveredBy allowedFieldPaths: Set<String>) -> Bool {
        allowedFieldPaths.contains(where: { allowedFieldPath in
            fieldPath == allowedFieldPath || fieldPath.hasPrefix("\(allowedFieldPath).")
        })
    }

    private func validateFieldKeys() throws {
        for (key, value) in data {
            if interpretsFieldPathKeys {
                _ = try FirestoreFieldPath.normalizeDocumentFieldPath(key)
            } else {
                try validateLiteralFieldNames(key: key, value: value)
            }
        }
        if interpretsFieldPathKeys {
            try FirestoreFieldPath.validateNoConflictingFieldPaths(
                try data.keys.map(FirestoreFieldPath.normalizeDocumentFieldPath),
                label: "updateData"
            )
        }
    }

    private func validateLiteralFieldNames(key: String, value: Any) throws {
        try FirestoreFieldPath.validateDocumentFieldName(key)
        if let dictionary = value as? [String: Any] {
            for (nestedKey, nestedValue) in dictionary {
                try validateLiteralFieldNames(key: nestedKey, value: nestedValue)
            }
        }
    }
}
