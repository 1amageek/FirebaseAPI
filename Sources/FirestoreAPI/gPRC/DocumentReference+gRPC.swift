//
//  DocumentReference+gRPC.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import GRPC
import NIO
import SwiftProtobuf
import NIOHPACK

extension DocumentReference {

    var name: String {
        return "\(database.path)/\(path)".normalized
    }

    public func getDocument<T: Decodable>(type: T.Type, firestore: Firestore, headers: HPACKHeaders) async throws -> T? {
        let snapshot = try await getDocument(firestore: firestore, headers: headers)
        if snapshot.isEmpty {
            return nil
        }
        guard let data = snapshot.data() else {
            return nil
        }
        return try FirestoreDecoder().decode(type, from: data)
    }

    public func getDocument(firestore: Firestore, headers: HPACKHeaders) async throws -> DocumentSnapshot {
        let client = Google_Firestore_V1_FirestoreNIOClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_GetDocumentRequest.with {
            $0.name = name
        }
        let call = client.getDocument(request, callOptions: callOptions)
        do {
            let document = try await call.response.get()
            return DocumentSnapshot(document: document, documentReference: self)
        } catch {
            return DocumentSnapshot(documentReference: self)
        }
    }

    public func setData(_ documentData: [String: Any], merge: Bool = false, firestore: Firestore, headers: HPACKHeaders) async throws {
        let documentData = DocumentData(data: documentData)
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let commitRequest = Google_Firestore_V1_CommitRequest.with {
            $0.database = firestore.database.database
            $0.writes = [
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
        }
        _ = try await client.commit(commitRequest, callOptions: callOptions)
    }

    public func updateData(_ fields: [String: Any], firestore: Firestore, headers: HPACKHeaders) async throws {
        let documentData = DocumentData(data: fields)
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let commitRequest = Google_Firestore_V1_CommitRequest.with {
            $0.database = firestore.database.database
            $0.writes = [
                Google_Firestore_V1_Write.with {
                    $0.update.name = name
                    $0.update.fields = documentData.getFields()
                    $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                        $0.fieldPaths = documentData.keys
                    }
                    let transforms = documentData.getFieldTransforms(documentPath: name)
                    if !transforms.isEmpty {
                        $0.updateTransforms = transforms
                    }
                }
            ]
        }
        _ = try await client.commit(commitRequest, callOptions: callOptions)
    }

    public func delete(firestore: Firestore, headers: HPACKHeaders) async throws {
        let client = Google_Firestore_V1_FirestoreNIOClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_DeleteDocumentRequest.with {
            $0.name = name
        }
        let call = client.deleteDocument(request, callOptions: callOptions)
        _ = try await call.response.get()
    }
}
