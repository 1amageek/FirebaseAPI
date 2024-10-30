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
    
    func getDocument(firestore: Firestore, headers: HPACKHeaders) async throws -> DocumentSnapshot {
        let client = Google_Firestore_V1_FirestoreNIOClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
        let request = Google_Firestore_V1_GetDocumentRequest.with {
            $0.name = name
            $0.mask = Google_Firestore_V1_DocumentMask()
        }
        let call = client.getDocument(request, callOptions: callOptions)
        do {
            let document = try await call.response.get()
            return DocumentSnapshot(document: document, documentReference: self)
        } catch {
            if let status = error as? GRPCStatus {
                switch status.code {
                case .notFound:
                    return DocumentSnapshot(documentReference: self)
                default:
                    throw FirestoreError.serverError(status)
                }
            }
            throw error
        }
    }
    
    func setData(_ documentData: [String: Any], merge: Bool = false, firestore: Firestore, headers: HPACKHeaders) async throws {
        let documentData = DocumentData(data: documentData)
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
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
    
    func updateData(_ fields: [String: Any], firestore: Firestore, headers: HPACKHeaders) async throws {
        let documentData = DocumentData(data: fields)
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
        let commitRequest = Google_Firestore_V1_CommitRequest.with {
            $0.database = firestore.database.database
            $0.writes = [
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
        }
        _ = try await client.commit(commitRequest, callOptions: callOptions)
    }
    
    func delete(firestore: Firestore, headers: HPACKHeaders) async throws {
        let client = Google_Firestore_V1_FirestoreNIOClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
        let request = Google_Firestore_V1_DeleteDocumentRequest.with {
            $0.name = name
        }
        let call = client.deleteDocument(request, callOptions: callOptions)
        _ = try await call.response.get()
    }
}

extension DocumentReference {
    
    func setData<T: Encodable>(_ data: T, merge: Bool = false, firestore: Firestore, headers: HPACKHeaders) async throws {
        let documentData = try FirestoreEncoder().encode(data)
        try await self.setData(documentData, merge: merge, firestore: firestore, headers: headers)
    }
    
    func updateData<T: Encodable>(_ data: T, firestore: Firestore, headers: HPACKHeaders) async throws {
        let updateData = try FirestoreEncoder().encode(data)
        try await self.updateData(updateData, firestore: firestore, headers: headers)
    }
}

extension DocumentReference {
    
    func getDocument<T: Decodable>(type: T.Type, firestore: Firestore, headers: HPACKHeaders) async throws -> T? {
        let snapshot = try await getDocument(firestore: firestore, headers: headers)
        if !snapshot.exists {
            return nil
        }
        guard let data = snapshot.data() else {
            return nil
        }
        return try FirestoreDecoder().decode(type, from: data, in: self)
    }
}
