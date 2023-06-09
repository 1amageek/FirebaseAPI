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

    public func getDocuments(firestore: Firestore, headers: HPACKHeaders) async throws -> QuerySnapshot {
        let client = Google_Firestore_V1_FirestoreNIOClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers)
        let request = Google_Firestore_V1_ListDocumentsRequest.with {
            $0.parent = name
            $0.collectionID = collectionID
        }
        let call = client.listDocuments(request, callOptions: callOptions)
        let response: Google_Firestore_V1_ListDocumentsResponse = try await call.response.get()
        return QuerySnapshot(response: response, collectionReference: self)
    }
}

extension CollectionReference {

    public func getDocuments<T: Decodable>(type: T.Type, firestore: Firestore, headers: HPACKHeaders) async throws -> [T] {
        let snapshot = try await getDocuments(firestore: firestore, headers: headers)
        return try snapshot.documents.compactMap { queryDocumentSnapshot in
            guard let data = queryDocumentSnapshot.data() else {
                return nil
            }
            return try FirestoreDecoder().decode(type, from: data, in: queryDocumentSnapshot.documentReference)
        }
    }
}
