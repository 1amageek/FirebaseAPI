import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    package func batchGetDocuments(
        documentReferences: [DocumentReference],
        transactionID: Data?
    ) async throws -> [DocumentSnapshot] {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)
        let requestMessage = try DocumentRequestCompiler(database: database).makeBatchGetDocumentsRequest(
            for: documentReferences,
            transactionID: transactionID
        )

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.batchGetDocuments(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_BatchGetDocumentsResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeDocumentSnapshots(from: responses)
            }
        }
    }

    package func runQuery(query: Query, transactionID: Data?) async throws -> QuerySnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)

        let queryPlan = try QueryCompiler(query: query).makeRunQueryPlan(transactionID: transactionID)

        return try await executeFiniteRPC(message: queryPlan.request) { request in
            try await client.runQuery(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_RunQueryResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeQuerySnapshot(
                    from: responses,
                    requiresResultOrderReversal: queryPlan.requiresResultOrderReversal
                )
            }
        }
    }

    internal func runQueryExplain(
        query: Query,
        options: FirestoreExplainOptions
    ) async throws -> QueryExplainResult {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)
        let responseMapper = ReadResponseMapper(runtime: self)

        let queryPlan = try QueryCompiler(query: query).makeRunQueryPlan(
            explainOptions: options
        )

        return try await executeFiniteRPC(message: queryPlan.request) { request in
            try await client.runQuery(
                request: request,
                options: self.callOptions
            ) { response in
                var responses: [Google_Firestore_V1_RunQueryResponse] = []
                for try await message in response.messages {
                    responses.append(message)
                }
                return try responseMapper.makeQueryExplainResult(
                    from: responses,
                    requiresResultOrderReversal: queryPlan.requiresResultOrderReversal
                )
            }
        }
    }
}
