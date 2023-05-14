//
//  Firestore+gRPC.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation
import GRPC
import NIO
import SwiftProtobuf
import NIOHPACK

extension Firestore {

    public func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?) async throws -> [DocumentSnapshot] {
        guard let accessToken = try await self.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_BatchGetDocumentsRequest.with {
            $0.database = self.database.database
            $0.documents = documentReferences.map { $0.path }
            if let transactionID {
                $0.transaction = transactionID
            }
        }
        let call = client.batchGetDocuments(request, callOptions: callOptions)
        var retrievedDocuments: [DocumentSnapshot] = []
        for try await response in call {
            switch response.result! {
                case .found(let document):
                    let documentReference = DocumentReference(name: document.name)
                    let documentSnapshot = DocumentSnapshot(document: document, documentReference: documentReference)
                    retrievedDocuments.append(documentSnapshot)
                case .missing(let name):
                    let documentReference = DocumentReference(name: name)
                    let documentSnapshot = DocumentSnapshot(document: nil, documentReference: documentReference)
                    retrievedDocuments.append(documentSnapshot)
            }
        }
        return retrievedDocuments
    }

    public func runQuery(query: Google_Firestore_V1_StructuredQuery, transactionID: Data?) async throws -> QuerySnapshot {
        guard let accessToken = try await self.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_RunQueryRequest.with {
            $0.parent = self.database.database
            $0.structuredQuery = query
            if let transactionID {
                $0.transaction = transactionID
            }
        }
        var documents: [QueryDocumentSnapshot] = []
        let call = client.runQuery(request, callOptions: callOptions)
        for try await response in call {
            let documentReference = DocumentReference(name: response.document.name)
            let snapshot = QueryDocumentSnapshot(document: response.document, documentReference: documentReference)
            documents.append(snapshot)
        }
        return QuerySnapshot(documents: documents)
    }

    public func beginTransaction(readOnly: Bool, readTime: Timestamp?) async throws -> Google_Firestore_V1_BeginTransactionResponse {
        guard let accessToken = try await self.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
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
        return try await client.beginTransaction(request, callOptions: callOptions)
    }

    public func commitTransaction(transactionID: Data, writeBatch: WriteBatch) async throws -> Google_Firestore_V1_CommitResponse {
        try await writeBatch._commit(transactionID: transactionID)
    }

    public func rollbackTransaction(transactionID: Data) async throws -> SwiftProtobuf.Google_Protobuf_Empty {
        guard let accessToken = try await self.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_RollbackRequest.with {
            $0.database = self.database.database
            $0.transaction = transactionID
        }
        return try await client.rollback(request, callOptions: callOptions)
    }
}
