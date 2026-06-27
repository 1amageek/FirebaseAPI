import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestorePipeline
import SwiftProtobuf

package struct PipelineCompiler {
    enum PipelineContext: Equatable, Sendable {
        case topLevel
        case nested
        case subquery
    }

    let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeExecutePipelineRequest(
        pipeline: FirestorePipeline,
        explainOptions: PipelineExplainOptions? = nil
    ) throws -> Google_Firestore_V1_ExecutePipelineRequest {
        guard !pipeline.stages.isEmpty else {
            throw FirestoreError.invalidQuery("Pipeline requires at least one stage.")
        }

        let compiledPipeline = try makePipeline(pipeline, context: .topLevel)
        return Google_Firestore_V1_ExecutePipelineRequest.with {
            $0.database = database.database
            $0.structuredPipeline = Google_Firestore_V1_StructuredPipeline.with {
                $0.pipeline = compiledPipeline
                if let explainOptions {
                    $0.options["explain_options"] = makeExplainOptions(explainOptions)
                }
            }
        }
    }
}
