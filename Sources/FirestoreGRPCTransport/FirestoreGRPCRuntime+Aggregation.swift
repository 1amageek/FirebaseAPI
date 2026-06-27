import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    func executeAggregate(query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        try await aggregate(query: query, fields: fields)
    }

    func executeExplainAggregation(
        query: Query,
        fields: [AggregateField],
        options: FirestoreExplainOptions
    ) async throws -> AggregateQueryExplainResult {
        try await aggregateExplain(query: query, fields: fields, options: options)
    }

    private func aggregate(query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)

        let requestMessage = try QueryCompiler(query: query).makeRunAggregationQueryRequest(fields: fields)

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.runAggregationQuery(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_RunAggregationQueryResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeAggregateSnapshot(from: responses)
            }
        }
    }

    private func aggregateExplain(
        query: Query,
        fields: [AggregateField],
        options: FirestoreExplainOptions
    ) async throws -> AggregateQueryExplainResult {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)

        let requestMessage = try QueryCompiler(query: query).makeRunAggregationQueryRequest(
            fields: fields,
            explainOptions: options
        )

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.runAggregationQuery(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_RunAggregationQueryResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeAggregateExplainResult(from: responses)
            }
        }
    }
}
