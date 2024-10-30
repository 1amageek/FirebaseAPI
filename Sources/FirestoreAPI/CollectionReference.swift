//
//  CollectionReference.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation
import GRPC
import NIOHPACK

public struct CollectionReference: Sendable {
    
    var database: Database
    var parentPath: String?
    public var collectionID: String
    
    public var path: String {
        if let parentPath {
            return "\(parentPath)/\(collectionID)".normalized
        } else {
            return "\(collectionID)".normalized
        }
    }
    
    init(_ database: Database, parentPath: String?, collectionID: String) {
        self.database = database
        self.parentPath = parentPath
        self.collectionID = collectionID
    }
    
    public var parent: CollectionReference? {
        guard let parentPath else { return nil }
        let components = parentPath
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        let path = components.dropLast(1).joined(separator: "/")
        let collectionID = String(components.last!)
        return CollectionReference(database, parentPath: path, collectionID: collectionID)
    }
    
    public func document(_ id: String = IDGenerator.generate()) -> DocumentReference {
        if id.isEmpty {
            fatalError("Document ID cannot be empty.")
        }
        let components = id
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        if components.count.isMultiple(of: 2) {
            fatalError("Invalid document path: \(id).")
        }
        return DocumentReference(database, parentPath: path, documentID: id)
    }
    
    public func addDocument(data: [String: Any], firestore: Firestore) async throws -> DocumentReference {
        let documentRef = self.document()
        try await documentRef.setData(data, firestore: firestore)
        return documentRef
    }
    
    public func addDocument<T: Encodable>(from data: T, firestore: Firestore) async throws -> DocumentReference {
        let documentRef = self.document()
        try await documentRef.setData(data, firestore: firestore)
        return documentRef
    }
    
    public func getDocuments(firestore: Firestore) async throws -> QuerySnapshot {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await getDocuments(firestore: firestore, headers: headers)
    }
    
    public func getDocuments<T: Decodable>(type: T.Type, firestore: Firestore) async throws -> [T] {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await getDocuments(type: type, firestore: firestore, headers: headers)
    }
    
    public func count(firestore: Firestore) async throws -> Int {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let client = Google_Firestore_V1_FirestoreAsyncClient(channel: firestore.channel)
        let callOptions = CallOptions(customMetadata: headers, timeLimit: .timeout(firestore.settings.timeout))
        
        let request = Google_Firestore_V1_RunAggregationQueryRequest.with {
            $0.parent = name
            $0.structuredAggregationQuery = Google_Firestore_V1_StructuredAggregationQuery.with {
                $0.aggregations = [
                    Google_Firestore_V1_StructuredAggregationQuery.Aggregation.with {
                        $0.count = Google_Firestore_V1_StructuredAggregationQuery.Aggregation.Count
                            .with {_ in }
                        $0.alias = "count"
                    }
                ]
                $0.structuredQuery = Google_Firestore_V1_StructuredQuery.with {
                    $0.from = [Google_Firestore_V1_StructuredQuery.CollectionSelector.with {
                        $0.collectionID = collectionID
                    }]
                }
            }
        }
        
        var count = 0
        let call = client.runAggregationQuery(request, callOptions: callOptions)
        for try await response in call {
            if let value = response.result.aggregateFields["count"]?.integerValue {
                count = Int(value)
                break
            }
        }
        return count
    }
}

extension CollectionReference: Codable {
    
    enum CodingKeys: CodingKey {
        case database
        case parentPath
        case collectionID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(database, forKey: .database)
        try container.encode(parentPath, forKey: .parentPath)
        try container.encode(collectionID, forKey: .collectionID)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let database = try container.decode(Database.self, forKey: .database)
        let parentPath = try container.decodeIfPresent(String.self, forKey: .parentPath)
        let collectionID = try container.decode(String.self, forKey: .collectionID)
        self.init(database, parentPath: parentPath, collectionID: collectionID)
    }
}
