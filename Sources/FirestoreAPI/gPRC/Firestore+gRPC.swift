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

    public func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?, headers: HPACKHeaders) async throws -> [DocumentSnapshot] {
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

    public func runQuery(query: Google_Firestore_V1_StructuredQuery, transactionID: Data?, headers: HPACKHeaders) async throws -> QuerySnapshot {
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let request = Google_Firestore_V1_RunQueryRequest.with {
            $0.parent = self.database.database
            $0.structuredQuery = query
            if let transactionID {
                $0.transaction = Data(base64Encoded: transactionID)!
            }
        }
        var documents: [QueryDocumentSnapshot] = []
        let call = client.runQuery(request)
        for try await response in call {
            let documentReference = DocumentReference(name: response.document.name)
            let snapshot = QueryDocumentSnapshot(document: response.document, documentReference: documentReference)
            documents.append(snapshot)
        }
        return QuerySnapshot(documents: documents)
    }


    public func beginTransaction(readOnly: Bool, readTime: Timestamp?, headers: HPACKHeaders) async throws -> Google_Firestore_V1_BeginTransactionResponse {
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

        let response = try await client.beginTransaction(request, callOptions: callOptions)
        return response
    }

    public func commitTransaction(transactionID: Data, writeBatch: WriteBatch, headers: HPACKHeaders) async throws -> Google_Firestore_V1_CommitResponse {
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_CommitRequest.with {
            $0.database = self.database.database
            $0.transaction = transactionID
            $0.writes = writeBatch.writes.map { write in
                Google_Firestore_V1_Write.with {
                    if let data = write.data {
                        let documentData = DocumentData(data: data)
                        $0.update.name = write.documentReference.name
                        $0.update.fields = documentData.getFields()
                        if let exists = write.exist {
                            $0.currentDocument = .with {
                                $0.exists = exists
                            }
                        }
                        if write.merge {
                            $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                                $0.fieldPaths = write.mergeFields ?? documentData.keys
                            }
                        }
                        let transforms = documentData.getFieldTransforms(documentPath: write.documentReference.name)
                        if !transforms.isEmpty {
                            $0.updateTransforms = transforms
                        }
                    } else {
                        $0.delete = write.documentReference.name
                        $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                            $0.fieldPaths = []
                        }
                    }
                }
            }
        }

        let response = try await client.commit(request, callOptions: callOptions)
        return response
    }

    public func rollbackTransaction(transactionID: Data, headers: HPACKHeaders) async throws -> SwiftProtobuf.Google_Protobuf_Empty {
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: self.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_RollbackRequest.with {
            $0.database = self.database.database
            $0.transaction = transactionID
        }
        let response = try await client.rollback(request, callOptions: callOptions)
        return response
    }
}
