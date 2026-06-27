import Foundation
import FirestoreCore

public struct PipelineQuerySnapshot: Sendable {
    public let resultRows: [PipelineQueryRow]
    public let executionTime: Timestamp?

    public init(rows: [PipelineQueryRow], executionTime: Timestamp?) {
        self.resultRows = rows
        self.executionTime = executionTime
    }

    public init(dataRows: [[String: Any]], executionTime: Timestamp?) throws {
        try self.init(
            rows: dataRows.map { try PipelineQueryRow(data: $0) },
            executionTime: executionTime
        )
    }

    package init(decodedRows: [[String: FirestoreDocumentValue]], executionTime: Timestamp?) {
        self.init(
            rows: decodedRows.map { PipelineQueryRow(fields: $0) },
            executionTime: executionTime
        )
    }

    public var rows: [[String: Any]] {
        resultRows.map(\.data)
    }
}
