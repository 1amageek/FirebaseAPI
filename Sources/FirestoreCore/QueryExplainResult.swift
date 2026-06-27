import Foundation

public struct QueryExplainResult: Sendable {
    public let snapshot: QuerySnapshot?
    public let metrics: FirestoreExplainMetrics

    public init(snapshot: QuerySnapshot?, metrics: FirestoreExplainMetrics) {
        self.snapshot = snapshot
        self.metrics = metrics
    }
}
