//
//  CollectionReference.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation
import GRPCCore
import GRPCProtobuf

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
    
    public func addDocument<Transport: ClientTransport>(data: [String: Any], firestore: Firestore<Transport>) async throws -> DocumentReference {
        let documentRef = self.document()
        try await documentRef.setData(data, firestore: firestore)
        return documentRef
    }

    public func addDocument<T: Encodable, Transport: ClientTransport>(from data: T, firestore: Firestore<Transport>) async throws -> DocumentReference {
        let documentRef = self.document()
        try await documentRef.setData(data, firestore: firestore)
        return documentRef
    }

    public func getDocuments<Transport: ClientTransport>(firestore: Firestore<Transport>) async throws -> QuerySnapshot {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await getDocuments(firestore: firestore, metadata: metadata)
    }

    public func getDocuments<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>) async throws -> [T] {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await getDocuments(type: type, firestore: firestore, metadata: metadata)
    }

    public func count<Transport: ClientTransport>(firestore: Firestore<Transport>) async throws -> Int {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }

        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")

        var requestMessage = Google_Firestore_V1_RunAggregationQueryRequest()
        requestMessage.parent = name
        requestMessage.structuredAggregationQuery = Google_Firestore_V1_StructuredAggregationQuery.with {
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

        let request = ClientRequest<Google_Firestore_V1_RunAggregationQueryRequest>(
            message: requestMessage,
            metadata: metadata
        )

        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)

        nonisolated(unsafe) var count = 0
        try await client.runAggregationQuery(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_RunAggregationQueryRequest>(),
            deserializer: ProtobufDeserializer<Google_Firestore_V1_RunAggregationQueryResponse>()
        ) { response in
            for try await message in response.messages {
                if let value = message.result.aggregateFields["count"]?.integerValue {
                    count = Int(value)
                    break
                }
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
