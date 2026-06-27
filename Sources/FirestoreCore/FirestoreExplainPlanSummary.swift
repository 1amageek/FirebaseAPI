import Foundation

public struct FirestoreExplainPlanSummary: Sendable, Equatable {
    public let indexesUsed: [[String: FirestoreExplainValue]]

    public init(indexesUsed: [[String: FirestoreExplainValue]]) {
        self.indexesUsed = indexesUsed
    }
}
