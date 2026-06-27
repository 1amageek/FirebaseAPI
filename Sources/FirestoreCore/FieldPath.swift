import Foundation

public struct FieldPath: Hashable, Sendable {
    private enum Storage: Hashable, Sendable {
        case documentID
        case fieldNames([String])
    }

    private let storage: Storage

    public init(_ fieldNames: [String]) {
        self.storage = .fieldNames(fieldNames)
    }

    public init(_ firstFieldName: String, _ additionalFieldNames: String...) {
        self.storage = .fieldNames([firstFieldName] + additionalFieldNames)
    }

    public static func documentID() -> FieldPath {
        FieldPath(storage: .documentID)
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    package var isDocumentID: Bool {
        if case .documentID = storage {
            return true
        }
        return false
    }

    package func rpcFieldPath() throws -> String {
        switch storage {
        case .documentID:
            return "__name__"
        case .fieldNames(let fieldNames):
            return try FirestoreFieldPath.encode(fieldNames)
        }
    }
}

package enum FirestoreFieldPath {
    private static let maximumFieldNameByteCount = 1_500

    package static func encode(_ fieldNames: [String]) throws -> String {
        guard !fieldNames.isEmpty else {
            throw FirestoreError.invalidFieldPath("FieldPath requires at least one field name.")
        }
        return try fieldNames.map(encodeSegment).joined(separator: ".")
    }

    package static func normalize(_ fieldPath: String) throws -> String {
        try encode(split(fieldPath))
    }

    package static func normalizeDocumentFieldPath(_ fieldPath: String) throws -> String {
        try encode(splitDocumentFieldPath(fieldPath))
    }

    package static func validateNoConflictingFieldPaths(
        _ fieldPaths: [String],
        label: String
    ) throws {
        let sortedFieldPaths = fieldPaths.sorted()
        var previousFieldPath: String?
        for fieldPath in sortedFieldPaths {
            if let previousFieldPath {
                if fieldPath == previousFieldPath {
                    throw FirestoreError.invalidFieldPath("\(label) contains duplicate field path '\(fieldPath)'.")
                }
                if fieldPath.hasPrefix("\(previousFieldPath).") {
                    throw FirestoreError.invalidFieldPath("\(label) contains conflicting field paths '\(previousFieldPath)' and '\(fieldPath)'.")
                }
            }
            previousFieldPath = fieldPath
        }
    }

    package static func split(_ fieldPath: String) throws -> [String] {
        guard !fieldPath.isEmpty else {
            throw FirestoreError.invalidFieldPath("Field path cannot be empty.")
        }

        var segments: [String] = []
        var current = ""
        var isQuoted = false
        var isEscaping = false
        var isQuotedSegment = false

        for character in fieldPath {
            if isQuoted {
                if isEscaping {
                    current.append(character)
                    isEscaping = false
                } else if character == "\\" {
                    isEscaping = true
                } else if character == "`" {
                    isQuoted = false
                } else {
                    current.append(character)
                }
                continue
            }

            if character == "." {
                try appendSegment(current, to: &segments)
                current = ""
                isQuotedSegment = false
            } else if character == "`" {
                guard current.isEmpty && !isQuotedSegment else {
                    throw FirestoreError.invalidFieldPath("Quoted field path segment must start at a segment boundary.")
                }
                isQuoted = true
                isQuotedSegment = true
            } else {
                current.append(character)
            }
        }

        guard !isQuoted else {
            throw FirestoreError.invalidFieldPath("Quoted field path segment is not closed.")
        }
        guard !isEscaping else {
            throw FirestoreError.invalidFieldPath("Quoted field path segment ends with an incomplete escape.")
        }

        try appendSegment(current, to: &segments)
        return segments
    }

    package static func splitDocumentFieldPath(_ fieldPath: String) throws -> [String] {
        let segments = try split(fieldPath)
        for segment in segments {
            try validateDocumentFieldName(segment)
        }
        return segments
    }

    package static func validateFieldName(_ fieldName: String) throws {
        guard !fieldName.isEmpty else {
            throw FirestoreError.invalidFieldPath("Field name cannot be empty.")
        }
        guard fieldName.utf8.count <= maximumFieldNameByteCount else {
            throw FirestoreError.invalidFieldPath("Field name exceeds 1,500 bytes.")
        }
    }

    package static func validateDocumentFieldName(_ fieldName: String) throws {
        try validateFieldName(fieldName)
        guard !(fieldName.hasPrefix("__") && fieldName.hasSuffix("__")) else {
            throw FirestoreError.invalidFieldPath("Field name cannot use reserved Firestore field name syntax.")
        }
    }

    package static func encodeFieldPathDictionary(_ fields: [FieldPath: Any]) throws -> [String: Any] {
        var encodedFields: [String: Any] = [:]
        for (fieldPath, value) in fields {
            encodedFields[try fieldPath.rpcFieldPath()] = value
        }
        return encodedFields
    }

    package static func encodeFieldPaths(_ fieldPaths: [FieldPath]) throws -> [String] {
        try fieldPaths.map { try $0.rpcFieldPath() }
    }

    private static func encodeSegment(_ segment: String) throws -> String {
        try validateFieldName(segment)
        if isSimpleFieldName(segment) {
            return segment
        }

        let escaped = segment.reduce(into: "") { result, character in
            if character == "`" || character == "\\" {
                result.append("\\")
            }
            result.append(character)
        }
        return "`\(escaped)`"
    }

    private static func appendSegment(_ segment: String, to segments: inout [String]) throws {
        try validateFieldName(segment)
        segments.append(segment)
    }

    private static func isSimpleFieldName(_ fieldName: String) -> Bool {
        guard let first = fieldName.unicodeScalars.first else {
            return false
        }
        guard first == "_" || isASCIIAlpha(first) else {
            return false
        }
        return fieldName.unicodeScalars.allSatisfy { scalar in
            scalar == "_" || isASCIIAlpha(scalar) || isASCIIDigit(scalar)
        }
    }

    private static func isASCIIAlpha(_ scalar: Unicode.Scalar) -> Bool {
        (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
    }

    private static func isASCIIDigit(_ scalar: Unicode.Scalar) -> Bool {
        (48...57).contains(Int(scalar.value))
    }
}
