import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestorePipeline
import FirestoreRPCSupport
import SwiftProtobuf

package struct PipelineResponseMapper {
    private let decoder: FirestoreDocumentDataDecoder
    private let runtime: (any FirestoreReferenceRuntime)?

    package init(runtime: (any FirestoreReferenceRuntime)? = nil) {
        self.runtime = runtime
        self.decoder = FirestoreDocumentDataDecoder(runtime: runtime)
    }

    package func makeSnapshot(
        from responses: [Google_Firestore_V1_ExecutePipelineResponse]
    ) throws -> PipelineQuerySnapshot {
        var rows: [PipelineQueryRow] = []
        for response in responses {
            for document in response.results {
                rows.append(try makeRow(from: document))
            }
        }
        let executionTime = responses.reversed().first(where: { $0.hasExecutionTime })?.executionTime
        return PipelineQuerySnapshot(
            rows: rows,
            executionTime: executionTime.map { Timestamp(seconds: $0.seconds, nanos: $0.nanos) }
        )
    }

    package func makeExplainResult(
        from responses: [Google_Firestore_V1_ExecutePipelineResponse],
        options: PipelineExplainOptions
    ) throws -> PipelineExplainResult {
        let snapshot = try makeOptionalSnapshot(from: responses)
        let stats = try makeExplainStats(
            from: responses.reversed().first(where: { $0.hasExplainStats })?.explainStats,
            options: options
        )
        return PipelineExplainResult(snapshot: snapshot, stats: stats)
    }

    private func makeOptionalSnapshot(
        from responses: [Google_Firestore_V1_ExecutePipelineResponse]
    ) throws -> PipelineQuerySnapshot? {
        let hasSnapshotContent = responses.contains { response in
            response.hasExecutionTime || !response.results.isEmpty
        }
        guard hasSnapshotContent else {
            return nil
        }
        return try makeSnapshot(from: responses)
    }

    private func makeRow(from document: Google_Firestore_V1_Document) throws -> PipelineQueryRow {
        let documentReference = document.name.isEmpty
            ? nil
            : try makeDocumentReference(name: document.name)
        let createTime = document.hasCreateTime
            ? Timestamp(seconds: document.createTime.seconds, nanos: document.createTime.nanos)
            : nil
        let updateTime = document.hasUpdateTime
            ? Timestamp(seconds: document.updateTime.seconds, nanos: document.updateTime.nanos)
            : nil

        return PipelineQueryRow(
            fields: try decoder.decode(fields: document.fields),
            documentReference: documentReference,
            createTime: createTime,
            updateTime: updateTime
        )
    }

    private func makeExplainStats(
        from stats: Google_Firestore_V1_ExplainStats?,
        options: PipelineExplainOptions
    ) throws -> PipelineExplainStats {
        guard let stats, stats.hasData else {
            return PipelineExplainStats(
                outputFormat: options.outputFormat,
                text: nil,
                json: nil,
                rawTypeURL: nil,
                rawData: nil
            )
        }

        let data = stats.data
        guard data.isA(Google_Protobuf_StringValue.self) else {
            return PipelineExplainStats(
                outputFormat: options.outputFormat,
                text: nil,
                json: nil,
                rawTypeURL: data.typeURL,
                rawData: data.value
            )
        }

        let stringValue = try Google_Protobuf_StringValue(unpackingAny: data).value
        return PipelineExplainStats(
            outputFormat: options.outputFormat,
            text: options.outputFormat == .text ? stringValue : nil,
            json: options.outputFormat == .json ? stringValue : nil,
            rawTypeURL: data.typeURL,
            rawData: data.value
        )
    }

    private func makeDocumentReference(name: String) throws -> DocumentReference {
        let reference = try DocumentReference(name: name, runtime: runtime)
        try validateDatabase(reference.database)
        return reference
    }

    private func validateDatabase(_ database: Database) throws {
        guard let runtime else {
            return
        }
        guard database == runtime.runtimeDatabase else {
            throw FirestoreError.databaseMismatch(
                expected: runtime.runtimeDatabase.database,
                actual: database.database
            )
        }
    }
}
