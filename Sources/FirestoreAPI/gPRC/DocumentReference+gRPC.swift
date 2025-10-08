//
//  DocumentReference+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf

extension DocumentReference {

    var name: String {
        return "\(database.path)/\(path)".normalized
    }

    func getDocument<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> DocumentSnapshot {
        let grpcClient = GRPCClient(transport: firestore.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        var requestMessage = Google_Firestore_V1_GetDocumentRequest()
        requestMessage.name = name

        let request = ClientRequest<Google_Firestore_V1_GetDocumentRequest>(
            message: requestMessage,
            metadata: metadata
        )

        do {
            let document = try await client.getDocument(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_GetDocumentRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_Document>()
            ) { response in
                try response.message
            }
            return DocumentSnapshot(document: document, documentReference: self)
        } catch let error as RPCError {
            if error.code == .notFound {
                return DocumentSnapshot(documentReference: self)
            }
            throw FirestoreError.rpcError(error)
        } catch {
            throw error
        }
    }

    func setData<Transport: ClientTransport>(_ documentData: [String: Any], merge: Bool = false, firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let grpcClient = GRPCClient(transport: firestore.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)
        let documentData = DocumentData(data: documentData)

        var requestMessage = Google_Firestore_V1_CommitRequest()
        requestMessage.database = firestore.database.database
        requestMessage.writes = [
            Google_Firestore_V1_Write.with {
                $0.update.name = name
                $0.update.fields = documentData.getFields()
                if merge {
                    $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                        $0.fieldPaths = documentData.keys
                    }
                }
                let transforms = documentData.getFieldTransforms(documentPath: name)
                if !transforms.isEmpty {
                    $0.updateTransforms = transforms
                }
            }
        ]

        let request = ClientRequest<Google_Firestore_V1_CommitRequest>(
            message: requestMessage,
            metadata: metadata
        )

        _ = try await client.commit(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_CommitRequest>(),
            deserializer: ProtobufDeserializer<Google_Firestore_V1_CommitResponse>()
        ) { response in
            try response.message
        }
    }

    func updateData<Transport: ClientTransport>(_ fields: [String: Any], firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let grpcClient = GRPCClient(transport: firestore.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)
        let documentData = DocumentData(data: fields)

        var requestMessage = Google_Firestore_V1_CommitRequest()
        requestMessage.database = firestore.database.database
        requestMessage.writes = [
            Google_Firestore_V1_Write.with {
                $0.update.name = name
                $0.update.fields = documentData.getFields()
                $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                    $0.fieldPaths = documentData.keys
                }
                $0.currentDocument = Google_Firestore_V1_Precondition.with {
                    $0.exists = true
                }
                let transforms = documentData.getFieldTransforms(documentPath: name)
                if !transforms.isEmpty {
                    $0.updateTransforms = transforms
                }
            }
        ]

        let request = ClientRequest<Google_Firestore_V1_CommitRequest>(
            message: requestMessage,
            metadata: metadata
        )

        _ = try await client.commit(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_CommitRequest>(),
            deserializer: ProtobufDeserializer<Google_Firestore_V1_CommitResponse>()
        ) { response in
            try response.message
        }
    }

    func delete<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let grpcClient = GRPCClient(transport: firestore.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        var requestMessage = Google_Firestore_V1_DeleteDocumentRequest()
        requestMessage.name = name

        let request = ClientRequest<Google_Firestore_V1_DeleteDocumentRequest>(
            message: requestMessage,
            metadata: metadata
        )

        _ = try await client.deleteDocument(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_DeleteDocumentRequest>(),
            deserializer: ProtobufDeserializer<SwiftProtobuf.Google_Protobuf_Empty>()
        ) { response in
            try response.message
        }
    }
}

extension DocumentReference {

    func setData<T: Encodable, Transport: ClientTransport>(_ data: T, merge: Bool = false, firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let documentData = try FirestoreEncoder().encode(data)
        try await self.setData(documentData, merge: merge, firestore: firestore, metadata: metadata)
    }

    func updateData<T: Encodable, Transport: ClientTransport>(_ data: T, firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let updateData = try FirestoreEncoder().encode(data)
        try await self.updateData(updateData, firestore: firestore, metadata: metadata)
    }
}

extension DocumentReference {

    func getDocument<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>, metadata: Metadata) async throws -> T? {
        let snapshot = try await getDocument(firestore: firestore, metadata: metadata)
        if !snapshot.exists {
            return nil
        }
        guard let data = snapshot.data() else {
            return nil
        }
        return try FirestoreDecoder().decode(type, from: data, in: self)
    }
}
