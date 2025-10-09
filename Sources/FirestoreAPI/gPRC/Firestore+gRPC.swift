import Foundation
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf
import Logging

extension Firestore {

    internal func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?) async throws -> [DocumentSnapshot] {
        let grpcClient = GRPCClient(transport: self.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_BatchGetDocumentsRequest()
        requestMessage.database = self.database.database
        requestMessage.documents = documentReferences.map { $0.name }
        if let transactionID {
            requestMessage.transaction = transactionID
        }

        let request = ClientRequest<Google_Firestore_V1_BatchGetDocumentsRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: 30.0
        )

        return try await retryHandler.execute(FirestoreOperation {
            nonisolated(unsafe) var retrievedDocuments: [DocumentSnapshot] = []

            try await client.batchGetDocuments(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_BatchGetDocumentsRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_BatchGetDocumentsResponse>()
            ) { response in
                for try await message in response.messages {
                    switch message.result {
                    case .found(let document):
                        let documentReference = DocumentReference(name: document.name)
                        let documentSnapshot = DocumentSnapshot(
                            document: document,
                            documentReference: documentReference
                        )
                        retrievedDocuments.append(documentSnapshot)
                    case .missing(let name):
                        let documentReference = DocumentReference(name: name)
                        let documentSnapshot = DocumentSnapshot(
                            document: nil,
                            documentReference: documentReference
                        )
                        retrievedDocuments.append(documentSnapshot)
                    case .none:
                        break
                    }
                }
            }

            return retrievedDocuments
        })
    }

    internal func runQuery(query: Google_Firestore_V1_StructuredQuery, transactionID: Data?) async throws -> QuerySnapshot {
        let grpcClient = GRPCClient(transport: self.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_RunQueryRequest()
        requestMessage.parent = self.database.database
        requestMessage.structuredQuery = query
        if let transactionID {
            requestMessage.transaction = transactionID
        }

        let request = ClientRequest<Google_Firestore_V1_RunQueryRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: 30.0
        )

        return try await retryHandler.execute(FirestoreOperation {
            nonisolated(unsafe) var documents: [QueryDocumentSnapshot] = []

            try await client.runQuery(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_RunQueryRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_RunQueryResponse>()
            ) { response in
                for try await message in response.messages {
                    if message.hasDocument {
                        let documentReference = DocumentReference(name: message.document.name)
                        let snapshot = QueryDocumentSnapshot(
                            document: message.document,
                            documentReference: documentReference
                        )
                        documents.append(snapshot)
                    }
                }
            }

            return QuerySnapshot(documents: documents)
        })
    }

    internal func beginTransaction(readOnly: Bool, readTime: Timestamp?) async throws -> Google_Firestore_V1_BeginTransactionResponse {
        let grpcClient = GRPCClient(transport: self.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_BeginTransactionRequest()
        requestMessage.database = self.database.database
        if readOnly {
            if let readTime = readTime {
                requestMessage.options.readOnly.readTime = Google_Protobuf_Timestamp.with {
                    $0.seconds = readTime.seconds
                    $0.nanos = readTime.nanos
                }
            } else {
                requestMessage.options.readOnly = Google_Firestore_V1_TransactionOptions.ReadOnly()
            }
        } else {
            requestMessage.options.readWrite = Google_Firestore_V1_TransactionOptions.ReadWrite()
        }

        let request = ClientRequest<Google_Firestore_V1_BeginTransactionRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: 30.0
        )

        return try await retryHandler.execute(FirestoreOperation {
            try await client.beginTransaction(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_BeginTransactionRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_BeginTransactionResponse>()
            ) { response in
                try response.message
            }
        })
    }

    internal func commitTransaction(transactionID: Data, writeBatch: WriteBatch<Transport>) async throws -> Google_Firestore_V1_CommitResponse {
        return try await writeBatch._commit(transactionID: transactionID)
    }

    internal func rollbackTransaction(transactionID: Data) async throws -> SwiftProtobuf.Google_Protobuf_Empty {
        let grpcClient = GRPCClient(transport: self.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_RollbackRequest()
        requestMessage.database = self.database.database
        requestMessage.transaction = transactionID

        let request = ClientRequest<Google_Firestore_V1_RollbackRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: 30.0
        )

        return try await retryHandler.execute(FirestoreOperation {
            try await client.rollback(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_RollbackRequest>(),
                deserializer: ProtobufDeserializer<SwiftProtobuf.Google_Protobuf_Empty>()
            ) { response in
                try response.message
            }
        })
    }

    internal func listen(target: Google_Firestore_V1_Target) async throws -> AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error> {
        let grpcClient = GRPCClient(transport: self.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }

        let authMetadata: Metadata = ["authorization": "Bearer \(accessToken)"]
        let databasePath = self.database.database

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = StreamingClientRequest<Google_Firestore_V1_ListenRequest>(
                        metadata: authMetadata,
                        producer: { writer in
                            // Send initial request with target
                            var initialMessage = Google_Firestore_V1_ListenRequest()
                            initialMessage.database = databasePath
                            initialMessage.addTarget = target
                            try await writer.write(initialMessage)

                            // Keep the stream open - the connection stays alive until cancelled
                            // The server will send updates as they occur
                        }
                    )

                    _ = try await client.listen(
                        request: request,
                        serializer: ProtobufSerializer<Google_Firestore_V1_ListenRequest>(),
                        deserializer: ProtobufDeserializer<Google_Firestore_V1_ListenResponse>()
                    ) { response in
                        Task {
                            do {
                                for try await message in response.messages {
                                    continuation.yield(message)
                                }
                                continuation.finish()
                            } catch {
                                continuation.finish(throwing: error)
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    internal func aggregate(query: Google_Firestore_V1_StructuredQuery, aggregations: [Google_Firestore_V1_StructuredAggregationQuery.Aggregation]) async throws -> [String: Google_Firestore_V1_Value] {
        let grpcClient = GRPCClient(transport: self.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_RunAggregationQueryRequest()
        requestMessage.parent = self.database.database
        requestMessage.structuredAggregationQuery = Google_Firestore_V1_StructuredAggregationQuery.with {
            $0.structuredQuery = query
            $0.aggregations = aggregations
        }

        let request = ClientRequest<Google_Firestore_V1_RunAggregationQueryRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: 30.0
        )

        return try await retryHandler.execute(FirestoreOperation {
            try await client.runAggregationQuery(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_RunAggregationQueryRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_RunAggregationQueryResponse>()
            ) { response in
                for try await result in response.messages {
                    return result.result.aggregateFields
                }
                throw FirestoreError.noResult
            }
        })
    }
}

private struct FirestoreOperation<T>: FirestoreRetryable {
    private let operation: @Sendable () async throws -> T

    init(_ operation: @escaping @Sendable () async throws -> T) {
        self.operation = operation
    }

    func execute() async throws -> T {
        try await operation()
    }
}
