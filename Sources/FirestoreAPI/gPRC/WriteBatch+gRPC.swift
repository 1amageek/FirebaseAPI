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
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let commitRequest = Google_Firestore_V1_CommitRequest.with {
            $0.database = firestore.database.database
            $0.writes = writes.map { write in
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
        _ = try await client.commit(commitRequest, callOptions: callOptions)
    }
}
