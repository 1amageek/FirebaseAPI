import Foundation
import GRPC
import NIO
import SwiftProtobuf
import NIOHTTP1
import NIOHPACK
import Logging

extension Firestore {
    
    internal func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?) async throws -> [DocumentSnapshot] {
        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }
        
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(self.settings.timeout))
        
        let request = Google_Firestore_V1_BatchGetDocumentsRequest.with {
            $0.database = self.database.database
            $0.documents = documentReferences.map { $0.name }
            if let transactionID {
                $0.transaction = transactionID
            }
        }
        
        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: TimeAmount.seconds(30).timeInterval
        )
        
        return try await retryHandler.execute(FirestoreOperation {
            var retrievedDocuments: [DocumentSnapshot] = []
            let call = client.batchGetDocuments(request, callOptions: callOptions)
            
            for try await response in call {
                switch response.result! {
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
                }
            }
            return retrievedDocuments
        })
    }
    
    internal func runQuery(query: Google_Firestore_V1_StructuredQuery, transactionID: Data?) async throws -> QuerySnapshot {
        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }
        
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(self.settings.timeout))
        
        let request = Google_Firestore_V1_RunQueryRequest.with {
            $0.parent = self.database.database
            $0.structuredQuery = query
            if let transactionID {
                $0.transaction = transactionID
            }
        }
        
        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: TimeAmount.seconds(30).timeInterval
        )
        
        return try await retryHandler.execute(FirestoreOperation {
            var documents: [QueryDocumentSnapshot] = []
            let call = client.runQuery(request, callOptions: callOptions)
            
            for try await response in call {
                let documentReference = DocumentReference(name: response.document.name)
                let snapshot = QueryDocumentSnapshot(
                    document: response.document,
                    documentReference: documentReference
                )
                documents.append(snapshot)
            }
            
            return QuerySnapshot(documents: documents)
        })
    }
    
    internal func beginTransaction(readOnly: Bool, readTime: Timestamp?) async throws -> Google_Firestore_V1_BeginTransactionResponse {
        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }
        
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(self.settings.timeout))
        
        let request = Google_Firestore_V1_BeginTransactionRequest.with {
            $0.database = self.database.database
            if readOnly {
                if let readTime = readTime {
                    $0.options.readOnly.readTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = readTime.seconds
                        $0.nanos = readTime.nanos
                    }
                } else {
                    $0.options.readOnly = Google_Firestore_V1_TransactionOptions.ReadOnly()
                }
            } else {
                $0.options.readWrite = Google_Firestore_V1_TransactionOptions.ReadWrite()
            }
        }
        
        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: TimeAmount.seconds(30).timeInterval
        )
        
        return try await retryHandler.execute(FirestoreOperation {
            return try await client.beginTransaction(request, callOptions: callOptions)
        })
    }
    
    internal func commitTransaction(transactionID: Data, writeBatch: WriteBatch) async throws -> Google_Firestore_V1_CommitResponse {
        return try await writeBatch._commit(transactionID: transactionID)
    }
    
    internal func rollbackTransaction(transactionID: Data) async throws -> SwiftProtobuf.Google_Protobuf_Empty {
        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }
        
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(self.settings.timeout))
        
        let request = Google_Firestore_V1_RollbackRequest.with {
            $0.database = self.database.database
            $0.transaction = transactionID
        }
        
        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: TimeAmount.seconds(30).timeInterval
        )
        
        return try await retryHandler.execute(FirestoreOperation {
            return try await client.rollback(request, callOptions: callOptions)
        })
    }
    
    internal func listen(target: Google_Firestore_V1_Target) async throws -> AsyncThrowingStream<Google_Firestore_V1_ListenResponse, Error> {
        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }
        
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
        
        let initialRequest = Google_Firestore_V1_ListenRequest.with {
            $0.database = self.database.database
            $0.addTarget = target
        }
        
        let requests = AsyncStream<Google_Firestore_V1_ListenRequest> { continuation in
            continuation.yield(initialRequest)
            continuation.finish()
        }
        
        let responseStream = client.listen(requests, callOptions: callOptions)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in responseStream {
                        continuation.yield(response)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    internal func aggregate(query: Google_Firestore_V1_StructuredQuery, aggregations: [Google_Firestore_V1_StructuredAggregationQuery.Aggregation]) async throws -> [String: Google_Firestore_V1_Value] {
        guard let accessToken = try await self.getAccessToken() else {
            throw FirestoreError.invalidAccessToken("Access token is empty")
        }
        
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(self.settings.timeout))
        
        let request = Google_Firestore_V1_RunAggregationQueryRequest.with {
            $0.parent = self.database.database
            $0.structuredAggregationQuery = Google_Firestore_V1_StructuredAggregationQuery.with {
                $0.structuredQuery = query
                $0.aggregations = aggregations
            }
        }
        
        let retryHandler = FirestoreRetryHandler(
            strategy: settings.retryStrategy,
            maxAttempts: settings.maxConcurrentLimits,
            maxDuration: TimeAmount.seconds(30).timeInterval
        )
        
        return try await retryHandler.execute(FirestoreOperation {
            let response = client.runAggregationQuery(request, callOptions: callOptions)
            for try await result in response {
                return result.result.aggregateFields
            }
            throw FirestoreError.noResult
        })
    }
}

private struct FirestoreOperation<T>: FirestoreRetryable {
    private let operation: () async throws -> T
    
    init(_ operation: @escaping () async throws -> T) {
        self.operation = operation
    }
    
    func execute() async throws -> T {
        try await operation()
    }
}
