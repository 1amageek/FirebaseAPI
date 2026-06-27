import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct QueryPredicateFilterCompiler {
    package let database: Database
    package let parentPath: String?
    package let collectionID: String
    package let allDescendants: Bool

    package init(
        database: Database,
        parentPath: String?,
        collectionID: String,
        allDescendants: Bool = false
    ) {
        self.database = database
        self.parentPath = parentPath
        self.collectionID = collectionID
        self.allDescendants = allDescendants
    }

    package func makeFilter(
        from predicate: QueryPredicate
    ) throws -> Google_Firestore_V1_StructuredQuery.Filter? {
        switch predicate {
        case .or(let predicates):
            let filters = try predicates.compactMap(makeFilter)
            return makeCompositeFilter(op: .or, filters: filters)

        case .and(let predicates):
            let filters = try predicates.compactMap(makeFilter)
            return makeCompositeFilter(op: .and, filters: filters)

        case .isEqualTo(let field, let value):
            if value is NSNull {
                return try makeUnaryFilter(field: field, op: .isNull)
            }
            if isNaNValue(value) {
                return try makeUnaryFilter(field: field, op: .isNan)
            }
            return try makeFieldFilter(field: field, op: .equal, value: value)

        case .isNotEqualTo(let field, let value):
            if value is NSNull {
                return try makeUnaryFilter(field: field, op: .isNotNull)
            }
            if isNaNValue(value) {
                return try makeUnaryFilter(field: field, op: .isNotNan)
            }
            return try makeFieldFilter(field: field, op: .notEqual, value: value)

        case .isIn(let field, let value):
            return try makeFieldFilter(field: field, op: .in, value: value)

        case .isNotIn(let field, let value):
            return try makeFieldFilter(field: field, op: .notIn, value: value)

        case .arrayContains(let field, let value):
            return try makeFieldFilter(field: field, op: .arrayContains, value: value)

        case .arrayContainsAny(let field, let value):
            return try makeFieldFilter(field: field, op: .arrayContainsAny, value: value)

        case .isLessThan(let field, let value):
            return try makeFieldFilter(field: field, op: .lessThan, value: value)

        case .isGreaterThan(let field, let value):
            return try makeFieldFilter(field: field, op: .greaterThan, value: value)

        case .isLessThanOrEqualTo(let field, let value):
            return try makeFieldFilter(field: field, op: .lessThanOrEqual, value: value)

        case .isGreaterThanOrEqualTo(let field, let value):
            return try makeFieldFilter(field: field, op: .greaterThanOrEqual, value: value)

        case .isEqualToDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .equal)

        case .isNotEqualToDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .notEqual)

        case .isInDocumentID(let documentIDs):
            return try makeDocumentIDArrayFilter(documentIDs: documentIDs, op: .in)

        case .isNotInDocumentID(let documentIDs):
            return try makeDocumentIDArrayFilter(documentIDs: documentIDs, op: .notIn)

        case .arrayContainsDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .arrayContains)

        case .arrayContainsAnyDocumentID(let documentIDs):
            return try makeDocumentIDArrayFilter(documentIDs: documentIDs, op: .arrayContainsAny)

        case .isLessThanDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .lessThan)

        case .isGreaterThanDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .greaterThan)

        case .isLessThanOrEqualToDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .lessThanOrEqual)

        case .isGreaterThanOrEqualToDocumentID(let documentID):
            return try makeDocumentIDFilter(documentID: documentID, op: .greaterThanOrEqual)

        case .orderBy,
             .limitTo,
             .limitToLast,
             .startAt,
             .startAfter,
             .endAt,
             .endBefore,
             .findNearest:
            return nil
        }
    }

    private func makeCompositeFilter(
        op: Google_Firestore_V1_StructuredQuery.CompositeFilter.Operator,
        filters: [Google_Firestore_V1_StructuredQuery.Filter]
    ) -> Google_Firestore_V1_StructuredQuery.Filter {
        Google_Firestore_V1_StructuredQuery.Filter.with {
            $0.compositeFilter = Google_Firestore_V1_StructuredQuery.CompositeFilter.with {
                $0.op = op
                $0.filters = filters
            }
        }
    }

    private func makeUnaryFilter(
        field: String,
        op: Google_Firestore_V1_StructuredQuery.UnaryFilter.Operator
    ) throws -> Google_Firestore_V1_StructuredQuery.Filter {
        let fieldPath = try FirestoreFieldPath.normalize(field)
        return Google_Firestore_V1_StructuredQuery.Filter.with {
            $0.unaryFilter = Google_Firestore_V1_StructuredQuery.UnaryFilter.with {
                $0.op = op
                $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                    $0.fieldPath = fieldPath
                }
            }
        }
    }

    private func makeFieldFilter(
        field: String,
        op: Google_Firestore_V1_StructuredQuery.FieldFilter.Operator,
        value: Any
    ) throws -> Google_Firestore_V1_StructuredQuery.Filter {
        let fieldPath = try FirestoreFieldPath.normalize(field)
        let firestoreValue: Google_Firestore_V1_Value
        switch op {
        case .in, .notIn, .arrayContainsAny:
            guard let values = value as? [Any] else {
                throw FirestoreError.invalidQuery("Membership filters require an array value.")
            }
            firestoreValue = try FirestoreValueEncoder.encodeQueryMembershipArray(values, path: fieldPath)
        default:
            firestoreValue = try FirestoreValueEncoder.encodeValue(value, path: fieldPath)
        }
        return Google_Firestore_V1_StructuredQuery.Filter.with {
            $0.fieldFilter = Google_Firestore_V1_StructuredQuery.FieldFilter.with {
                $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                    $0.fieldPath = fieldPath
                }
                $0.op = op
                $0.value = firestoreValue
            }
        }
    }

    private func makeDocumentIDFilter(
        documentID: String,
        op: Google_Firestore_V1_StructuredQuery.FieldFilter.Operator
    ) throws -> Google_Firestore_V1_StructuredQuery.Filter {
        let value = try makeDocumentReferenceValue(documentID: documentID)
        return Google_Firestore_V1_StructuredQuery.Filter.with {
            $0.fieldFilter = Google_Firestore_V1_StructuredQuery.FieldFilter.with {
                $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                    $0.fieldPath = "__name__"
                }
                $0.op = op
                $0.value = value
            }
        }
    }

    private func makeDocumentIDArrayFilter(
        documentIDs: [String],
        op: Google_Firestore_V1_StructuredQuery.FieldFilter.Operator
    ) throws -> Google_Firestore_V1_StructuredQuery.Filter {
        let value = try makeDocumentReferenceArrayValue(documentIDs: documentIDs)
        return Google_Firestore_V1_StructuredQuery.Filter.with {
            $0.fieldFilter = Google_Firestore_V1_StructuredQuery.FieldFilter.with {
                $0.field = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                    $0.fieldPath = "__name__"
                }
                $0.op = op
                $0.value = value
            }
        }
    }

    private func makeDocumentReferenceValue(
        documentID: String
    ) throws -> Google_Firestore_V1_Value {
        try Google_Firestore_V1_Value.with {
            $0.referenceValue = try makeDocumentReferencePath(documentID: documentID)
        }
    }

    private func makeDocumentReferenceArrayValue(
        documentIDs: [String]
    ) throws -> Google_Firestore_V1_Value {
        let values = try documentIDs.map(makeDocumentReferenceValue)
        return Google_Firestore_V1_Value.with {
            $0.arrayValue = Google_Firestore_V1_ArrayValue.with {
                $0.values = values
            }
        }
    }

    private func makeDocumentReferencePath(documentID: String) throws -> String {
        let normalizedDocumentID = documentID.normalized

        if allDescendants {
            let relativeDocumentPath: String
            if normalizedDocumentID.hasPrefix("\(database.path)/") {
                relativeDocumentPath = String(normalizedDocumentID.dropFirst(database.path.count + 1))
            } else {
                relativeDocumentPath = normalizedDocumentID
            }

            do {
                _ = try FirestorePathValidator.documentPath(relativeDocumentPath)
            } catch {
                throw FirestoreError.invalidQuery("Collection group document ID filter value must be a valid document path.")
            }
            return "\(database.path)/\(relativeDocumentPath)".normalized
        }

        guard !normalizedDocumentID.isEmpty else {
            throw FirestoreError.invalidQuery("Collection document ID filter value must not be empty.")
        }
        guard !normalizedDocumentID.contains("/") else {
            throw FirestoreError.invalidQuery("Collection document ID filter value must be a plain document ID.")
        }

        if let parentPath {
            return "\(database.path)/\(parentPath)/\(collectionID)/\(normalizedDocumentID)".normalized
        }

        return "\(database.path)/\(collectionID)/\(normalizedDocumentID)".normalized
    }

    private func isNaNValue(_ value: Any) -> Bool {
        if let double = value as? Double {
            return double.isNaN
        }
        if let float = value as? Float {
            return float.isNaN
        }
        if let number = value as? NSNumber {
            return number.doubleValue.isNaN
        }
        return false
    }
}
