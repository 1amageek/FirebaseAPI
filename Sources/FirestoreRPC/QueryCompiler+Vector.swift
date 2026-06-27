import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

extension QueryCompiler {
    func makeFindNearest(
        _ query: FirestoreFindNearestQuery
    ) throws -> Google_Firestore_V1_StructuredQuery.FindNearest {
        let vectorField = try FirestoreFieldPath.normalize(query.vectorField)
        guard query.limit > 0 else {
            throw FirestoreError.invalidQuery("findNearest limit must be greater than zero.")
        }
        guard query.limit <= 1_000 else {
            throw FirestoreError.invalidQuery("findNearest limit supports at most 1,000 results.")
        }
        if let distanceResultField = query.distanceResultField {
            try FirestoreFieldPath.validateDocumentFieldName(distanceResultField)
        }

        return try Google_Firestore_V1_StructuredQuery.FindNearest.with {
            $0.vectorField = Google_Firestore_V1_StructuredQuery.FieldReference.with {
                $0.fieldPath = vectorField
            }
            $0.queryVector = try FirestoreValueEncoder.encodeVector(
                query.queryVector,
                path: "findNearest.queryVector"
            )
            $0.distanceMeasure = makeDistanceMeasure(query.distanceMeasure)
            $0.limit = Google_Protobuf_Int32Value.with {
                $0.value = Int32(query.limit)
            }
            if let distanceResultField = query.distanceResultField {
                $0.distanceResultField = distanceResultField
            }
            if let distanceThreshold = query.distanceThreshold {
                $0.distanceThreshold = Google_Protobuf_DoubleValue.with {
                    $0.value = distanceThreshold
                }
            }
        }
    }

    private func makeDistanceMeasure(
        _ measure: FirestoreVectorDistanceMeasure
    ) -> Google_Firestore_V1_StructuredQuery.FindNearest.DistanceMeasure {
        switch measure {
        case .euclidean:
            return .euclidean
        case .cosine:
            return .cosine
        case .dotProduct:
            return .dotProduct
        }
    }
}
