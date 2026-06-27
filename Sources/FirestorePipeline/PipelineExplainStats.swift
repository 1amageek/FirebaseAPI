import Foundation
import FirestoreCore

public struct PipelineExplainStats: Sendable, Equatable {
    public let outputFormat: PipelineExplainOutputFormat
    public let text: String?
    public let json: String?
    package let rawTypeURL: String?
    package let rawData: Data?

    public init(
        outputFormat: PipelineExplainOutputFormat,
        text: String?,
        json: String?
    ) {
        self.init(
            outputFormat: outputFormat,
            text: text,
            json: json,
            rawTypeURL: nil,
            rawData: nil
        )
    }

    package init(
        outputFormat: PipelineExplainOutputFormat,
        text: String?,
        json: String?,
        rawTypeURL: String?,
        rawData: Data?
    ) {
        self.outputFormat = outputFormat
        self.text = text
        self.json = json
        self.rawTypeURL = rawTypeURL
        self.rawData = rawData
    }
}
