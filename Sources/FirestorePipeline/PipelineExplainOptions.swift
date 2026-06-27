import Foundation
import FirestoreCore

public struct PipelineExplainOptions: Sendable, Equatable {
    public let mode: PipelineExplainMode
    public let outputFormat: PipelineExplainOutputFormat

    public init(
        mode: PipelineExplainMode = .explain,
        outputFormat: PipelineExplainOutputFormat = .text
    ) {
        self.mode = mode
        self.outputFormat = outputFormat
    }

    public static let explainText = PipelineExplainOptions(mode: .explain, outputFormat: .text)
    public static let analyzeText = PipelineExplainOptions(mode: .analyze, outputFormat: .text)
    public static let explainJSON = PipelineExplainOptions(mode: .explain, outputFormat: .json)
    public static let analyzeJSON = PipelineExplainOptions(mode: .analyze, outputFormat: .json)
}
