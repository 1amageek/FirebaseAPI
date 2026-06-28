import Foundation
import FirestorePipeline

public protocol FirestoreAdminPipelineClient: Sendable {
    func pipeline() -> FirestorePipeline
    func execute(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot
    func explain(_ pipeline: FirestorePipeline, options: PipelineExplainOptions) async throws -> PipelineExplainResult
}

public extension FirestoreAdminPipelineClient {
    func explain(_ pipeline: FirestorePipeline) async throws -> PipelineExplainResult {
        try await explain(pipeline, options: .explainText)
    }
}
