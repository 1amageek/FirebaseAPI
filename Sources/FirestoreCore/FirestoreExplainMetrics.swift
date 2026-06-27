import Foundation

public struct FirestoreExplainMetrics: Sendable, Equatable {
    public let planSummary: FirestoreExplainPlanSummary
    public let executionStats: FirestoreExplainExecutionStats?

    public init(
        planSummary: FirestoreExplainPlanSummary,
        executionStats: FirestoreExplainExecutionStats?
    ) {
        self.planSummary = planSummary
        self.executionStats = executionStats
    }
}
