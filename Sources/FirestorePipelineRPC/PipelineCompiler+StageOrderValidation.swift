import FirestoreCore
import FirestorePipeline

extension PipelineCompiler {
    func validatePipelineStageOrder(
        _ stages: [PipelineStage],
        context: PipelineContext
    ) throws {
        for (index, stage) in stages.enumerated() where isPipelineInputStage(stage.name) {
            guard index == stages.startIndex else {
                throw FirestoreError.invalidQuery("\(stage.name) stage must be the first Pipeline stage.")
            }
        }
        for stage in stages where stage.name == "subcollection" {
            guard context == .subquery else {
                throw FirestoreError.invalidQuery("subcollection stage must be used inside a Pipeline subquery.")
            }
        }
        for (index, stage) in stages.enumerated() where isDMLOutputStage(stage.name) {
            guard index == stages.index(before: stages.endIndex) else {
                throw FirestoreError.invalidQuery("\(stage.name) stage must be the final Pipeline stage.")
            }
        }
        for (index, stage) in stages.enumerated() where stage.name == "search" {
            let precedingStages = stages[..<index]
            guard precedingStages.allSatisfy({ isPipelineInputStage($0.name) }) else {
                throw FirestoreError.invalidQuery("search stage must be the first non-input Pipeline stage.")
            }
        }
    }

    func isDMLOutputStage(_ name: String) -> Bool {
        name == "delete" || name == "update"
    }

    func isPipelineInputStage(_ name: String) -> Bool {
        switch name {
        case "collection", "collection_group", "database", "documents", "literals", "subcollection":
            return true
        default:
            return false
        }
    }
}
