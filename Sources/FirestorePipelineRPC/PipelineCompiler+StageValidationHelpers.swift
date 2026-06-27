import FirestoreCore
import FirestorePipeline

extension PipelineCompiler {
    func requireSingleStringArgument(
        _ stage: PipelineStage,
        description: String
    ) throws -> String {
        guard stage.arguments.count == 1 else {
            throw FirestoreError.invalidQuery("\(stage.name) stage requires exactly one \(description).")
        }
        guard case .string(let value) = stage.arguments[0].storage else {
            throw FirestoreError.invalidQuery("\(stage.name) stage \(description) must be a string.")
        }
        return value
    }

    func requireSingleArgument(
        _ stage: PipelineStage,
        description: String
    ) throws -> PipelineValue {
        guard stage.arguments.count == 1 else {
            throw FirestoreError.invalidQuery("\(stage.name) stage requires exactly one \(description).")
        }
        return stage.arguments[0]
    }

    func requireSingleIntegerArgument(
        _ stage: PipelineStage,
        description: String
    ) throws -> Int64 {
        guard stage.arguments.count == 1 else {
            throw FirestoreError.invalidQuery("\(stage.name) stage requires exactly one \(description).")
        }
        guard case .int(let value) = stage.arguments[0].storage else {
            throw FirestoreError.invalidQuery("\(stage.name) stage \(description) must be an integer.")
        }
        return value
    }

    func requireAtLeastOneArgument(
        _ stage: PipelineStage,
        description: String
    ) throws {
        guard !stage.arguments.isEmpty else {
            throw FirestoreError.invalidQuery("\(stage.name) stage requires at least one \(description).")
        }
    }

    func requireNoOptions(_ stage: PipelineStage) throws {
        guard stage.options.isEmpty else {
            throw FirestoreError.invalidQuery("\(stage.name) stage does not accept options.")
        }
    }

    func requireOnlyOptions(_ stage: PipelineStage, allowed: Set<String>) throws {
        for optionName in stage.options.keys where !allowed.contains(optionName) {
            throw FirestoreError.invalidQuery("\(stage.name) stage does not support \(optionName) option.")
        }
    }
}
