import Foundation
import FirestoreCore

public struct PipelineExplainResult: Sendable {
    public let snapshot: PipelineQuerySnapshot?
    public let stats: PipelineExplainStats

    public init(snapshot: PipelineQuerySnapshot?, stats: PipelineExplainStats) {
        self.snapshot = snapshot
        self.stats = stats
    }
}
