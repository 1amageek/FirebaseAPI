import FirestoreCore
import FirestorePipeline

extension PipelineCompiler {
    func validateSearchStage(_ stage: PipelineStage) throws {
        try requireOnlyOptions(stage, allowed: ["query", "sort", "add_fields"])
        guard stage.arguments.isEmpty else {
            throw FirestoreError.invalidQuery("search stage uses options and does not accept positional arguments.")
        }
        guard stage.options["query"] != nil else {
            throw FirestoreError.invalidQuery("search stage requires a query option.")
        }
        if let sort = stage.options["sort"] {
            guard case .array = sort.storage else {
                throw FirestoreError.invalidQuery("search stage sort option must be an array.")
            }
        }
        if let addFields = stage.options["add_fields"] {
            guard case .array = addFields.storage else {
                throw FirestoreError.invalidQuery("search stage add_fields option must be an array.")
            }
        }
    }

    func validateLiteralsStage(_ stage: PipelineStage) throws {
        try requireAtLeastOneArgument(stage, description: "literal document")
        for argument in stage.arguments {
            guard case .map = argument.storage else {
                throw FirestoreError.invalidQuery("literals stage accepts only map arguments.")
            }
        }
        try requireNoOptions(stage)
    }

    func validateRemoveFieldsStage(_ stage: PipelineStage) throws {
        try requireAtLeastOneArgument(stage, description: "field name")
        for argument in stage.arguments {
            guard case .string(let field) = argument.storage else {
                throw FirestoreError.invalidQuery("remove_fields stage accepts only field name strings.")
            }
            guard !field.isEmpty else {
                throw FirestoreError.invalidQuery("remove_fields stage field names must not be empty.")
            }
        }
        try requireNoOptions(stage)
    }

    func validateAggregateStage(_ stage: PipelineStage) throws {
        try requireAtLeastOneArgument(stage, description: "accumulator expression")
        try requireOnlyOptions(stage, allowed: ["groups"])
        if let groups = stage.options["groups"] {
            guard case .array = groups.storage else {
                throw FirestoreError.invalidQuery("aggregate stage groups option must be an array.")
            }
        }
    }

    func validateReplaceWithStage(_ stage: PipelineStage) throws {
        guard stage.arguments.count == 2 else {
            throw FirestoreError.invalidQuery("replace_with stage requires value and mode arguments.")
        }
        guard case .string(let mode) = stage.arguments[1].storage else {
            throw FirestoreError.invalidQuery("replace_with stage mode must be a string.")
        }
        let supportedModes: Set<String> = [
            PipelineReplaceMode.fullReplace.rawValue,
            PipelineReplaceMode.mergeOverwriteExisting.rawValue,
            PipelineReplaceMode.mergeKeepExisting.rawValue
        ]
        guard supportedModes.contains(mode) else {
            throw FirestoreError.invalidQuery("replace_with stage mode is unsupported.")
        }
        try requireNoOptions(stage)
    }

    func validateSampleStage(_ stage: PipelineStage) throws {
        if stage.arguments.isEmpty {
            try requireOnlyOptions(stage, allowed: ["percentage"])
            guard let percentage = stage.options["percentage"] else {
                throw FirestoreError.invalidQuery("sample stage requires count or percentage.")
            }
            guard case .double(let value) = percentage.storage else {
                throw FirestoreError.invalidQuery("sample stage percentage must be a double.")
            }
            guard value > 0 else {
                throw FirestoreError.invalidQuery("sample stage percentage must be greater than zero.")
            }
            return
        }
        let count = try requireSingleIntegerArgument(stage, description: "sample count")
        guard count > 0 else {
            throw FirestoreError.invalidQuery("sample stage count must be greater than zero.")
        }
        try requireNoOptions(stage)
    }

    func validateUnnestStage(_ stage: PipelineStage) throws {
        _ = try requireSingleArgument(stage, description: "array expression")
        try requireOnlyOptions(stage, allowed: ["index_field"])
        if let indexField = stage.options["index_field"] {
            guard case .string(let fieldName) = indexField.storage else {
                throw FirestoreError.invalidQuery("unnest stage index_field option must be a string.")
            }
            try FirestoreFieldPath.validateFieldName(fieldName)
        }
    }

    func validateUnionStage(_ stage: PipelineStage) throws {
        try requireAtLeastOneArgument(stage, description: "pipeline argument")
        for argument in stage.arguments {
            guard case .pipeline = argument.storage else {
                throw FirestoreError.invalidQuery("union stage accepts only pipeline arguments.")
            }
        }
        try requireNoOptions(stage)
    }
}
