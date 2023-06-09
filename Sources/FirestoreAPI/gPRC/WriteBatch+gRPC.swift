//
//  WriteBatch+gRPC.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation
import GRPC
import NIO
import SwiftProtobuf
import NIOHPACK

extension WriteBatch {

    public func commit() async throws {
        _ = try await _commit()
    }

    func _commit(transactionID: Data? = nil) async throws -> Google_Firestore_V1_CommitResponse {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_CommitRequest.with {
            $0.database = firestore.database.database
            if let transactionID {
                $0.transaction = transactionID
            }
            $0.writes = self.writes.map { write in
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
        }
        let response = try await client.commit(request, callOptions: callOptions)
        return response
    }
}
