import FirestoreCore
import FirestoreProtobuf

extension QueryCompiler {
    package func makeRunAggregationQueryRequest(
        aggregations: [Google_Firestore_V1_StructuredAggregationQuery.Aggregation],
        explainOptions: FirestoreExplainOptions? = nil
    ) throws -> Google_Firestore_V1_RunAggregationQueryRequest {
        let structuredQuery = try makeStructuredQuery()
        return Google_Firestore_V1_RunAggregationQueryRequest.with {
            $0.parent = query.name
            $0.structuredAggregationQuery = Google_Firestore_V1_StructuredAggregationQuery.with {
                $0.structuredQuery = structuredQuery
                $0.aggregations = aggregations
            }
            if let explainOptions {
                $0.explainOptions = makeExplainOptions(explainOptions)
            }
        }
    }

    package func makeRunAggregationQueryRequest(
        fields: [AggregateField],
        explainOptions: FirestoreExplainOptions? = nil
    ) throws -> Google_Firestore_V1_RunAggregationQueryRequest {
        let aggregations = try makeAggregations(from: fields)
        return try makeRunAggregationQueryRequest(
            aggregations: aggregations,
            explainOptions: explainOptions
        )
    }

    private func makeAggregations(
        from fields: [AggregateField]
    ) throws -> [Google_Firestore_V1_StructuredAggregationQuery.Aggregation] {
        guard !fields.isEmpty else {
            throw FirestoreError.invalidQuery("Aggregation query requires at least one aggregate field.")
        }
        guard fields.count <= 5 else {
            throw FirestoreError.invalidQuery("Aggregation query supports at most five aggregate fields.")
        }

        var aliases: Set<String> = []
        return try fields.map { field in
            try validateAggregationAlias(field.alias)
            guard aliases.insert(field.alias).inserted else {
                throw FirestoreError.invalidQuery("Aggregation aliases must be unique.")
            }
            return try makeAggregation(from: field)
        }
    }

    private func makeAggregation(
        from field: AggregateField
    ) throws -> Google_Firestore_V1_StructuredAggregationQuery.Aggregation {
        try Google_Firestore_V1_StructuredAggregationQuery.Aggregation.with {
            $0.alias = field.alias
            switch field.operation {
            case .count:
                $0.count = Google_Firestore_V1_StructuredAggregationQuery.Aggregation.Count.with { _ in }
            case .sum:
                let fieldReference = try requireAggregationFieldReference(for: field)
                $0.sum = Google_Firestore_V1_StructuredAggregationQuery.Aggregation.Sum.with {
                    $0.field = fieldReference
                }
            case .average:
                let fieldReference = try requireAggregationFieldReference(for: field)
                $0.avg = Google_Firestore_V1_StructuredAggregationQuery.Aggregation.Avg.with {
                    $0.field = fieldReference
                }
            }
        }
    }

    private func requireAggregationFieldReference(
        for field: AggregateField
    ) throws -> Google_Firestore_V1_StructuredQuery.FieldReference {
        guard let fieldPath = field.fieldPath else {
            throw FirestoreError.invalidQuery("Aggregation field path is required for \(field.operation.rawValue).")
        }
        return try makeAggregationFieldReference(fieldPath)
    }

    private func makeAggregationFieldReference(
        _ fieldPath: String
    ) throws -> Google_Firestore_V1_StructuredQuery.FieldReference {
        guard !fieldPath.isEmpty else {
            throw FirestoreError.invalidQuery("Aggregation field path must not be empty.")
        }
        let normalizedFieldPath = try FirestoreFieldPath.normalize(fieldPath)
        return Google_Firestore_V1_StructuredQuery.FieldReference.with {
            $0.fieldPath = normalizedFieldPath
        }
    }

    private func validateAggregationAlias(_ alias: String) throws {
        do {
            try FirestoreFieldPath.validateDocumentFieldName(alias)
        } catch FirestoreError.invalidFieldPath(let message) {
            throw FirestoreError.invalidQuery("Aggregation alias must be a valid Firestore field name. \(message)")
        }
    }
}
