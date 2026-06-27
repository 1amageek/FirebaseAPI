import FirestoreCore
import FirestoreProtobuf
import FirestorePipeline
import SwiftProtobuf

extension PipelineCompiler {
    func makePipeline(
        _ pipeline: FirestorePipeline,
        context: PipelineContext
    ) throws -> Google_Firestore_V1_Pipeline {
        try validatePipelineStageOrder(pipeline.stages, context: context)
        let stages = try pipeline.stages.map { try makeStage($0, context: context) }
        return Google_Firestore_V1_Pipeline.with {
            $0.stages = stages
        }
    }

    func makeStage(
        _ stage: PipelineStage,
        context: PipelineContext
    ) throws -> Google_Firestore_V1_Pipeline.Stage {
        try validateName(stage.name, label: "Pipeline stage")
        try validateOptionNames(stage.options.keys, label: "Pipeline stage option")
        try validateKnownStageArguments(stage)
        let arguments = try stage.arguments.map { try makeValue($0, context: context) }
        let options = try stage.options.mapValues { try makeValue($0, context: context) }
        return Google_Firestore_V1_Pipeline.Stage.with {
            $0.name = stage.name
            $0.args = arguments
            $0.options = options
        }
    }
}
