import Foundation
import FirestoreCore
import FirestorePipeline

package protocol FirestoreBatchWriteRuntime: FirestoreRuntimeIdentifying {
    func batchWrite(_ writes: [WriteData], labels: [String: String]) async throws -> FirestoreBulkWriteResult
}

package protocol FirestorePipelineRuntime: FirestoreRuntimeIdentifying {
    func executePipeline(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot
    func explainPipeline(_ pipeline: FirestorePipeline, options: PipelineExplainOptions) async throws -> PipelineExplainResult
}

package protocol FirestoreRuntime:
    FirestoreReferenceRuntime,
    FirestoreCollectionGroupRuntime,
    FirestoreBatchWriteRuntime,
    FirestorePipelineRuntime
{}

package extension FirestoreBatchWriteRuntime {
    func batchWrite(
        _ writes: [WriteData],
        labels: [String: String] = [:]
    ) async throws -> FirestoreBulkWriteResult {
        throw FirestoreError.invalidOperation("BatchWrite is not supported by this runtime.")
    }
}
