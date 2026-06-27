import FirestoreCore
import FirestorePipeline

extension PipelineCompiler {
    func validateFindNearestStage(_ stage: PipelineStage) throws {
        guard stage.name == "find_nearest" else {
            return
        }
        try requireOnlyOptions(
            stage,
            allowed: ["field", "vector_value", "distance_measure", "limit", "distance_field"]
        )
        guard stage.arguments.isEmpty else {
            throw FirestoreError.invalidQuery("find_nearest uses options and does not accept positional arguments.")
        }
        guard let field = stage.options["field"] else {
            throw FirestoreError.invalidQuery("find_nearest requires a field option.")
        }
        guard case .field(let fieldPath) = field.storage else {
            throw FirestoreError.invalidQuery("find_nearest field option must be a field reference.")
        }
        _ = try FirestoreFieldPath.normalize(fieldPath)
        guard let vectorValue = stage.options["vector_value"] else {
            throw FirestoreError.invalidQuery("find_nearest requires a vector_value option.")
        }
        try validatePipelineVectorValue(vectorValue, path: "find_nearest.vector_value")
        guard let distanceMeasure = stage.options["distance_measure"] else {
            throw FirestoreError.invalidQuery("find_nearest requires a distance_measure option.")
        }
        guard case .string(let value) = distanceMeasure.storage else {
            throw FirestoreError.invalidQuery("find_nearest distance_measure must be a string.")
        }
        let supportedMeasures = Set(FirestoreVectorDistanceMeasure.allCases.map(\.rawValue))
        guard supportedMeasures.contains(value) else {
            throw FirestoreError.invalidQuery("find_nearest distance_measure is unsupported.")
        }
        if let limit = stage.options["limit"] {
            guard case .int(let count) = limit.storage else {
                throw FirestoreError.invalidQuery("find_nearest limit must be an integer.")
            }
            guard count > 0 else {
                throw FirestoreError.invalidQuery("find_nearest limit must be greater than zero.")
            }
            guard count <= 1_000 else {
                throw FirestoreError.invalidQuery("find_nearest limit supports at most 1,000 results.")
            }
        }
        if let distanceField = stage.options["distance_field"] {
            guard case .string(let fieldName) = distanceField.storage else {
                throw FirestoreError.invalidQuery("find_nearest distance_field must be a string.")
            }
            try FirestoreFieldPath.validateFieldName(fieldName)
        }
    }

    func validatePipelineVectorValue(_ value: PipelineValue, path: String) throws {
        guard case .array(let values) = value.storage else {
            throw FirestoreError.invalidQuery("\(path) must be an array.")
        }
        guard !values.isEmpty else {
            throw FirestoreError.invalidQuery("\(path) must contain at least one dimension.")
        }
        guard values.count <= 2_048 else {
            throw FirestoreError.invalidQuery("\(path) exceeds 2,048 dimensions.")
        }
        for dimension in values {
            switch dimension.storage {
            case .int, .double:
                continue
            default:
                throw FirestoreError.invalidQuery("\(path) must contain only numeric dimensions.")
            }
        }
    }
}
