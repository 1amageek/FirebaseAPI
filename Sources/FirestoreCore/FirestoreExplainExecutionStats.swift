import Foundation

public struct FirestoreExplainExecutionStats: Sendable, Equatable {
    public let resultsReturned: Int64
    public let executionDurationSeconds: Double?
    public let readOperations: Int64
    public let debugStats: [String: FirestoreExplainValue]

    public init(
        resultsReturned: Int64,
        executionDurationSeconds: Double?,
        readOperations: Int64,
        debugStats: [String: FirestoreExplainValue]
    ) {
        self.resultsReturned = resultsReturned
        self.executionDurationSeconds = executionDurationSeconds
        self.readOperations = readOperations
        self.debugStats = debugStats
    }
}
