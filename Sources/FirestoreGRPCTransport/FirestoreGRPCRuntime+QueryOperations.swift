import Foundation
import FirestoreCore
import FirestoreRPC
import FirestoreGRPCStubs
import FirestoreProtobuf
import GRPCCore

extension FirestoreGRPCRuntime {
    func executeRunQuery(_ query: Query) async throws -> QuerySnapshot {
        try await runQuery(query: query, transactionID: nil)
    }

    func executeExplain(
        query: Query,
        options: FirestoreExplainOptions
    ) async throws -> QueryExplainResult {
        try await runQueryExplain(query: query, options: options)
    }

    func executePartitionedQueries(
        for collectionGroup: CollectionGroup,
        partitionPointCount: Int,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [Query] {
        let compiler = PartitionQueryCompiler(collectionGroup: collectionGroup)
        let mapper = PartitionQueryResponseMapper(database: database, runtime: self)
        var pageToken = ""
        var responses: [Google_Firestore_V1_PartitionQueryResponse] = []

        repeat {
            let response = try await partitionQuery(
                request: try compiler.makePartitionQueryRequest(
                    partitionPointCount: partitionPointCount,
                    pageSize: pageSize,
                    pageToken: pageToken,
                    readTime: readTime
                )
            )
            responses.append(response)
            pageToken = response.nextPageToken
        } while !pageToken.isEmpty

        return try mapper.makePartitionedQueries(
            for: collectionGroup,
            partitionReferences: mapper.makePartitionReferences(from: responses)
        )
    }

    private func partitionQuery(
        request requestMessage: Google_Firestore_V1_PartitionQueryRequest
    ) async throws -> Google_Firestore_V1_PartitionQueryResponse {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: self.grpcClient)

        return try await executeFiniteRPC(message: requestMessage) { request in
            try await client.partitionQuery(
                request: request,
                options: self.callOptions
            ) { response in
                try response.message
            }
        }
    }

    func executeListen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        let queryCompiler = QueryCompiler(query: query)
        let sortOrders = try queryCompiler.makeUserVisibleSortOrders()
        let targetTemplate = try ListenTargetBuilder().makeQueryTarget(
            for: query,
            targetID: 0
        )
        let queryRuntime = query.runtime

        return ListenStreamCoordinator<QueryListenState, QuerySnapshot>(
            targetTemplate: targetTemplate,
            maxRetryAttempts: settings.maxRetryAttempts,
            retryStrategy: settings.retryStrategy,
            nextTargetID: { self.nextListenTargetID() },
            makeState: { targetID in
                QueryListenState(
                    targetID: targetID,
                    runtime: queryRuntime,
                    sortOrders: sortOrders
                )
            },
            reduceResponse: { state, response in
                try state.apply(response)
            },
            resumeToken: { state in
                state.resumeToken
            },
            openStream: { target in
                try await self.listen(target: target)
            }
        ).makeStream()
    }
}
