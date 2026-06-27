import Foundation

public struct AggregateQueryExplainResult: Sendable {
    public let snapshot: AggregateQuerySnapshot?
    public let metrics: FirestoreExplainMetrics

    public init(snapshot: AggregateQuerySnapshot?, metrics: FirestoreExplainMetrics) {
        self.snapshot = snapshot
        self.metrics = metrics
    }
}
