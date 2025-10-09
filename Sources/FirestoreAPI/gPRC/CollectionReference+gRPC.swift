//
//  CollectionReference+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf

extension CollectionReference {

    var name: String {
        if let parentPath {
            return "\(database.path)/\(parentPath)".normalized
        }
        return "\(database.path)".normalized
    }

    func getDocuments<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> QuerySnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)

        var requestMessage = Google_Firestore_V1_ListDocumentsRequest()
        requestMessage.parent = name
        requestMessage.collectionID = collectionID
        requestMessage.orderBy = "document_id"
        requestMessage.showMissing = false

        var documents: [QueryDocumentSnapshot] = []
        var pageToken: String?

        repeat {
            if let token = pageToken {
                requestMessage.pageToken = token
            }

            let request = ClientRequest<Google_Firestore_V1_ListDocumentsRequest>(
                message: requestMessage,
                metadata: metadata
            )

            do {
                let response = try await client.listDocuments(
                    request: request,
                    serializer: ProtobufSerializer<Google_Firestore_V1_ListDocumentsRequest>(),
                    deserializer: ProtobufDeserializer<Google_Firestore_V1_ListDocumentsResponse>()
                ) { response in
                    try response.message
                }

                documents.append(contentsOf: response.documents.map { document in
                    let documentReference = DocumentReference(name: document.name)
                    return QueryDocumentSnapshot(document: document, documentReference: documentReference)
                })
                pageToken = response.nextPageToken.isEmpty ? nil : response.nextPageToken
            } catch let error as RPCError {
                throw FirestoreError.rpcError(error)
            } catch {
                throw error
            }
        } while pageToken != nil

        return QuerySnapshot(documents: documents)
    }

    func getDocuments<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>, metadata: Metadata) async throws -> [T] {
        let snapshot = try await getDocuments(firestore: firestore, metadata: metadata)
        return try snapshot.documents.compactMap { queryDocumentSnapshot in
            guard let data = queryDocumentSnapshot.data() else {
                return nil
            }
            return try FirestoreDecoder().decode(type, from: data, in: queryDocumentSnapshot.documentReference)
        }
    }

    // TODO: Fix streaming API for grpc-swift-2
    // func streamDocuments<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) -> AsyncThrowingStream<QueryDocumentSnapshot, Error> {
    //     return AsyncThrowingStream { continuation in
    //         // Need to fix: ClientRequest streaming API changed in grpc-swift-2
    //         continuation.finish(throwing: FirestoreError.notImplemented)
    //     }
    // }

    func listCollectionIds<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> [String] {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)

        var requestMessage = Google_Firestore_V1_ListCollectionIdsRequest()
        requestMessage.parent = name

        let request = ClientRequest<Google_Firestore_V1_ListCollectionIdsRequest>(
            message: requestMessage,
            metadata: metadata
        )

        do {
            let response = try await client.listCollectionIds(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_ListCollectionIdsRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_ListCollectionIdsResponse>()
            ) { response in
                try response.message
            }
            return response.collectionIds
        } catch let error as RPCError {
            throw FirestoreError.rpcError(error)
        } catch {
            throw error
        }
    }
}
