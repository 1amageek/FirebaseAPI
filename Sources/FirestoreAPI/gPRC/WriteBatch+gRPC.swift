//
//  WriteBatch+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf

extension WriteBatch {

    public func commit() async throws {
        _ = try await _commit()
    }

    func _commit(transactionID: Data? = nil) async throws -> Google_Firestore_V1_CommitResponse {
        let grpcClient = GRPCClient(transport: firestore.transport)
        let client = Google_Firestore_V1_Firestore.Client(wrapping: grpcClient)

        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_CommitRequest()
        requestMessage.database = firestore.database.database
        if let transactionID {
            requestMessage.transaction = transactionID
        }
        requestMessage.writes = self.writes.map { write in
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
                }
            }
        }

        let request = ClientRequest<Google_Firestore_V1_CommitRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let response = try await client.commit(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_CommitRequest>(),
            deserializer: ProtobufDeserializer<Google_Firestore_V1_CommitResponse>()
        ) { response in
            try response.message
        }

        return response
    }
}
