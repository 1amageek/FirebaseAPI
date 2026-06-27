import Foundation
import FirestorePipeline
import FirestorePipelineRPC
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    internal func executePipelineQuery(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = PipelineResponseMapper(runtime: self)
        let requestMessage = try PipelineCompiler(database: database).makeExecutePipelineRequest(pipeline: pipeline)

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.executePipeline(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_ExecutePipelineResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeSnapshot(from: responses)
            }
        }
    }

    internal func executePipelineExplainQuery(
        _ pipeline: FirestorePipeline,
        options: PipelineExplainOptions
    ) async throws -> PipelineExplainResult {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = PipelineResponseMapper(runtime: self)
        let requestMessage = try PipelineCompiler(database: database).makeExecutePipelineRequest(
            pipeline: pipeline,
            explainOptions: options
        )

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.executePipeline(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_ExecutePipelineResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeExplainResult(from: responses, options: options)
            }
        }
    }
}
