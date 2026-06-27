import FirestoreCore
import FirestorePipeline

extension PipelineCompiler {
    func validateKnownStageArguments(_ stage: PipelineStage) throws {
        switch stage.name {
        case "collection":
            let path = try requireSingleStringArgument(stage, description: "collection path")
            _ = try FirestorePathValidator.collectionPath(path)
            try requireNoOptions(stage)
        case "collection_group":
            let groupID = try requireSingleStringArgument(stage, description: "collection group ID")
            _ = try FirestorePathValidator.collectionGroupID(groupID)
            try requireNoOptions(stage)
        case "subcollection":
            let collectionID = try requireSingleStringArgument(stage, description: "subcollection ID")
            _ = try FirestorePathValidator.collectionGroupID(collectionID)
            try requireNoOptions(stage)
        case "documents":
            guard !stage.arguments.isEmpty else {
                throw FirestoreError.invalidQuery("documents stage requires at least one document reference.")
            }
            for argument in stage.arguments {
                switch argument.storage {
                case .reference, .documentReference:
                    continue
                default:
                    throw FirestoreError.invalidQuery("documents stage accepts only document references.")
                }
            }
            try requireNoOptions(stage)
        case "literals":
            try validateLiteralsStage(stage)
        case "database":
            guard stage.arguments.isEmpty else {
                throw FirestoreError.invalidQuery("database stage does not accept positional arguments.")
            }
            try requireNoOptions(stage)
        case "where":
            _ = try requireSingleArgument(stage, description: "filter expression")
            try requireNoOptions(stage)
        case "limit":
            let count = try requireSingleIntegerArgument(stage, description: "limit count")
            guard count > 0 else {
                throw FirestoreError.invalidQuery("limit stage count must be greater than zero.")
            }
            try requireNoOptions(stage)
        case "offset":
            let count = try requireSingleIntegerArgument(stage, description: "offset count")
            guard count >= 0 else {
                throw FirestoreError.invalidQuery("offset stage count must not be negative.")
            }
            try requireNoOptions(stage)
        case "search":
            try validateSearchStage(stage)
        case "find_nearest":
            try validateFindNearestStage(stage)
        case "select":
            try requireAtLeastOneArgument(stage, description: "projection expression")
            try requireNoOptions(stage)
        case "add_fields":
            try requireAtLeastOneArgument(stage, description: "field assignment")
            try requireNoOptions(stage)
        case "remove_fields":
            try validateRemoveFieldsStage(stage)
        case "let":
            try requireAtLeastOneArgument(stage, description: "variable assignment")
            try requireNoOptions(stage)
        case "sort":
            try requireAtLeastOneArgument(stage, description: "sort ordering")
            try requireNoOptions(stage)
        case "aggregate":
            try validateAggregateStage(stage)
        case "distinct":
            try requireAtLeastOneArgument(stage, description: "distinct group expression")
            try requireNoOptions(stage)
        case "replace_with":
            try validateReplaceWithStage(stage)
        case "sample":
            try validateSampleStage(stage)
        case "unnest":
            try validateUnnestStage(stage)
        case "union":
            try validateUnionStage(stage)
        case "delete":
            guard stage.arguments.isEmpty else {
                throw FirestoreError.invalidQuery("delete stage does not accept positional arguments.")
            }
            try requireNoOptions(stage)
        case "update":
            try requireNoOptions(stage)
        default:
            return
        }
    }
}
