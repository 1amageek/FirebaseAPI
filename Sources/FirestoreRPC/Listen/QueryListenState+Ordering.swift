import Foundation
import FirestoreCore
import FirestoreProtobuf

extension QueryListenState {
    func insertionIndex(for document: Google_Firestore_V1_Document) -> Int {
        guard !sortOrders.isEmpty else {
            return documents.count
        }

        for index in rpcDocuments.indices {
            if compare(document, rpcDocuments[index]) == .orderedAscending {
                return index
            }
        }

        return documents.count
    }

    func compare(
        _ lhs: Google_Firestore_V1_Document,
        _ rhs: Google_Firestore_V1_Document
    ) -> ComparisonResult {
        for sortOrder in sortOrders {
            let comparison = compare(lhs, rhs, by: sortOrder)
            if comparison != .orderedSame {
                return sortOrder.descending ? comparison.reversed : comparison
            }
        }

        return FirestoreValueComparator.compare(
            documentNameValue(lhs.name),
            documentNameValue(rhs.name)
        )
    }

    func compare(
        _ lhs: Google_Firestore_V1_Document,
        _ rhs: Google_Firestore_V1_Document,
        by sortOrder: QuerySortOrder
    ) -> ComparisonResult {
        if sortOrder.fieldPath == "__name__" {
            return FirestoreValueComparator.compare(
                documentNameValue(lhs.name),
                documentNameValue(rhs.name)
            )
        }

        return FirestoreValueComparator.compare(
            fieldValue(in: lhs, fieldPath: sortOrder.fieldPath),
            fieldValue(in: rhs, fieldPath: sortOrder.fieldPath)
        )
    }

    func fieldValue(
        in document: Google_Firestore_V1_Document,
        fieldPath: String
    ) -> Google_Firestore_V1_Value? {
        let segments: [String]
        do {
            segments = try FirestoreFieldPath.split(fieldPath)
        } catch {
            return nil
        }

        guard let firstSegment = segments.first else {
            return nil
        }

        var currentValue = document.fields[firstSegment]
        for segment in segments.dropFirst() {
            guard case .mapValue(let mapValue)? = currentValue?.valueType else {
                return nil
            }
            currentValue = mapValue.fields[segment]
        }

        return currentValue
    }

    func documentNameValue(_ name: String) -> Google_Firestore_V1_Value {
        Google_Firestore_V1_Value.with {
            $0.referenceValue = name
        }
    }
}
