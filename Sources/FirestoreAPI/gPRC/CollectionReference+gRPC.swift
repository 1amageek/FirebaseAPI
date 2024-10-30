//
//  CollectionReference+gRPC.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import GRPC
import NIO
import SwiftProtobuf
import NIOHPACK

extension CollectionReference {
    
    var name: String {
        if let parentPath {
            return "\(database.path)/\(parentPath)".normalized
        }
        return "\(database.path)".normalized
    }
    
    func getDocuments(firestore: Firestore, headers: HPACKHeaders) async throws -> QuerySnapshot {
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
        
        var request = Google_Firestore_V1_ListDocumentsRequest.with {
            $0.parent = name
            $0.collectionID = collectionID
            $0.orderBy = "document_id"
            $0.showMissing = false
            $0.mask = Google_Firestore_V1_DocumentMask()
        }
        
        var documents: [QueryDocumentSnapshot] = []
        var pageToken: String?
        
        repeat {
            if let token = pageToken {
                request.pageToken = token
            }
            
            do {
                let response = try await client.listDocuments(request, callOptions: callOptions)
                documents.append(contentsOf: response.documents.map { document in
                    let documentReference = DocumentReference(name: document.name)
                    return QueryDocumentSnapshot(document: document, documentReference: documentReference)
                })
                pageToken = response.nextPageToken.isEmpty ? nil : response.nextPageToken
            } catch {
                if let status = error as? GRPCStatus {
                    throw FirestoreError.serverError(status)
                }
                throw error
            }
        } while pageToken != nil
        
        return QuerySnapshot(documents: documents)
    }
    
    func getDocuments<T: Decodable>(type: T.Type, firestore: Firestore, headers: HPACKHeaders) async throws -> [T] {
        let snapshot = try await getDocuments(firestore: firestore, headers: headers)
        return try snapshot.documents.compactMap { queryDocumentSnapshot in
            guard let data = queryDocumentSnapshot.data() else {
                return nil
            }
            return try FirestoreDecoder().decode(type, from: data, in: queryDocumentSnapshot.documentReference)
        }
    }
    
    func streamDocuments(firestore: Firestore, headers: HPACKHeaders) -> AsyncThrowingStream<QueryDocumentSnapshot, Error> {
        return AsyncThrowingStream { continuation in
            let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
            let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
            
            let initialRequest = Google_Firestore_V1_ListenRequest.with {
                $0.database = database.database
                $0.addTarget = Google_Firestore_V1_Target.with {
                    $0.query = Google_Firestore_V1_Target.QueryTarget.with {
                        $0.parent = name
                        $0.structuredQuery = Google_Firestore_V1_StructuredQuery.with {
                            $0.from = [Google_Firestore_V1_StructuredQuery.CollectionSelector.with {
                                $0.collectionID = collectionID
                            }]
                        }
                    }
                }
            }
            
            let requests = AsyncStream<Google_Firestore_V1_ListenRequest> { continuation in
                continuation.yield(initialRequest)
                continuation.finish()
            }
            
            Task {
                do {
                    let responses = client.listen(requests, callOptions: callOptions)
                    for try await response in responses {
                        switch response.responseType {
                        case .targetChange(let targetChange):
                            // Handle target change if needed
                            if targetChange.targetChangeType == .remove {
                                continuation.finish()
                            }
                        case .documentChange(let change):
                            let documentReference = DocumentReference(name: change.document.name)
                            let snapshot = QueryDocumentSnapshot(document: change.document, documentReference: documentReference)
                            continuation.yield(snapshot)
                        case .documentDelete(let change):
                            let documentReference = DocumentReference(name: change.document)
                            let snapshot = QueryDocumentSnapshot(document: nil, documentReference: documentReference)
                            continuation.yield(snapshot)
                        case .documentRemove(let change):
                            let documentReference = DocumentReference(name: change.document)
                            let snapshot = QueryDocumentSnapshot(document: nil, documentReference: documentReference)
                            continuation.yield(snapshot)
                        case .filter(_):
                            // Handle filter changes if needed
                            break
                        case nil:
                            // No response type
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func listCollectionIds(firestore: Firestore, headers: HPACKHeaders) async throws -> [String] {
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
        
        let request = Google_Firestore_V1_ListCollectionIdsRequest.with {
            $0.parent = name
        }
        
        do {
            let response = try await client.listCollectionIds(request, callOptions: callOptions)
            return response.collectionIds
        } catch {
            if let status = error as? GRPCStatus {
                throw FirestoreError.serverError(status)
            }
            throw error
        }
    }
}
