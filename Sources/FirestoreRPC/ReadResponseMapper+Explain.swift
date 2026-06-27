import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

extension ReadResponseMapper {
    package func makeQueryExplainResult(
        from responses: [Google_Firestore_V1_RunQueryResponse],
        requiresResultOrderReversal: Bool
    ) throws -> QueryExplainResult {
        guard let metricsResponse = responses.reversed().first(where: { $0.hasExplainMetrics }) else {
            throw FirestoreError.noResult
        }

        let metrics = makeExplainMetrics(from: metricsResponse.explainMetrics)
        let snapshot: QuerySnapshot?
        if responses.contains(where: { $0.hasDocument }) {
            snapshot = try makeQuerySnapshot(
                from: responses,
                requiresResultOrderReversal: requiresResultOrderReversal
            )
        } else if metrics.executionStats != nil {
            snapshot = QuerySnapshot(documents: [])
        } else {
            snapshot = nil
        }

        return QueryExplainResult(
            snapshot: snapshot,
            metrics: metrics
        )
    }

    package func makeAggregateExplainResult(
        from responses: [Google_Firestore_V1_RunAggregationQueryResponse]
    ) throws -> AggregateQueryExplainResult {
        guard let metricsResponse = responses.reversed().first(where: { $0.hasExplainMetrics }) else {
            throw FirestoreError.noResult
        }

        let metrics = makeExplainMetrics(from: metricsResponse.explainMetrics)
        let snapshot: AggregateQuerySnapshot?
        if let resultResponse = responses.first(where: { $0.hasResult }) {
            snapshot = try makeAggregateSnapshot(from: resultResponse.result.aggregateFields)
        } else if metrics.executionStats != nil {
            snapshot = AggregateQuerySnapshot(data: [:])
        } else {
            snapshot = nil
        }

        return AggregateQueryExplainResult(
            snapshot: snapshot,
            metrics: metrics
        )
    }

    func makeExplainMetrics(
        from metrics: Google_Firestore_V1_ExplainMetrics
    ) -> FirestoreExplainMetrics {
        let planSummary = metrics.hasPlanSummary
            ? makePlanSummary(from: metrics.planSummary)
            : FirestoreExplainPlanSummary(indexesUsed: [])
        let executionStats = metrics.hasExecutionStats
            ? makeExecutionStats(from: metrics.executionStats)
            : nil
        return FirestoreExplainMetrics(
            planSummary: planSummary,
            executionStats: executionStats
        )
    }

    func makePlanSummary(
        from summary: Google_Firestore_V1_PlanSummary
    ) -> FirestoreExplainPlanSummary {
        FirestoreExplainPlanSummary(
            indexesUsed: summary.indexesUsed.map { makeStructValue(from: $0) }
        )
    }

    func makeExecutionStats(
        from stats: Google_Firestore_V1_ExecutionStats
    ) -> FirestoreExplainExecutionStats {
        FirestoreExplainExecutionStats(
            resultsReturned: stats.resultsReturned,
            executionDurationSeconds: stats.hasExecutionDuration
                ? makeSeconds(from: stats.executionDuration)
                : nil,
            readOperations: stats.readOperations,
            debugStats: stats.hasDebugStats ? makeStructValue(from: stats.debugStats) : [:]
        )
    }

    func makeStructValue(
        from value: Google_Protobuf_Struct
    ) -> [String: FirestoreExplainValue] {
        value.fields.mapValues(makeExplainValue)
    }

    func makeExplainValue(
        from value: Google_Protobuf_Value
    ) -> FirestoreExplainValue {
        switch value.kind {
        case .nullValue:
            return .null
        case .numberValue(let value):
            return .number(value)
        case .stringValue(let value):
            return .string(value)
        case .boolValue(let value):
            return .bool(value)
        case .structValue(let value):
            return .map(makeStructValue(from: value))
        case .listValue(let value):
            return .list(value.values.map(makeExplainValue))
        case .none:
            return .null
        }
    }

    func makeSeconds(
        from duration: Google_Protobuf_Duration
    ) -> Double {
        Double(duration.seconds) + Double(duration.nanos) / 1_000_000_000
    }
}
