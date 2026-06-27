import FirestoreCore
public struct PipelineSwitchCase: Sendable {
    public let condition: PipelineValue
    public let result: PipelineValue

    public init(_ condition: PipelineValue, then result: PipelineValue) {
        self.condition = condition
        self.result = result
    }
}
