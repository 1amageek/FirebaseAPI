import FirestoreCore
import FirestorePipeline

extension PipelineCompiler {
    func validateKnownFunctionArguments(name: String, arguments: [PipelineValue]) throws {
        switch name {
        case "lambda":
            guard arguments.count == 2 else {
                throw FirestoreError.invalidQuery("lambda function requires parameters and body arguments.")
            }
            guard case .array(let parameters) = arguments[0].storage else {
                throw FirestoreError.invalidQuery("lambda function parameters must be an array.")
            }
            guard !parameters.isEmpty else {
                throw FirestoreError.invalidQuery("lambda function requires at least one parameter.")
            }
            for parameter in parameters {
                guard case .string(let name) = parameter.storage else {
                    throw FirestoreError.invalidQuery("lambda function parameters must be strings.")
                }
                try validateName(name, label: "Pipeline lambda parameter")
            }
        case "path":
            guard arguments.count == 1 else {
                throw FirestoreError.invalidQuery("path function requires exactly one path string argument.")
            }
            guard case .string = arguments[0].storage else {
                throw FirestoreError.invalidQuery("path function argument must be a string.")
            }
        case "vector":
            guard arguments.count == 1 else {
                throw FirestoreError.invalidQuery("vector function requires exactly one array argument.")
            }
            guard case .array = arguments[0].storage else {
                throw FirestoreError.invalidQuery("vector function argument must be an array.")
            }
        case "geo_distance":
            guard arguments.count == 2 else {
                throw FirestoreError.invalidQuery("geo_distance function requires exactly two arguments.")
            }
        default:
            return
        }
    }
}
