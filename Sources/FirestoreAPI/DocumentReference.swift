//
//  DocumentReference.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation
import GRPCCore

public struct DocumentReference: Sendable {
    
    var database: Database
    private var parentPath: String
    public var documentID: String
    public var path: String { "\(parentPath)/\(documentID)".normalized }
    
    init(_ database: Database, parentPath: String, documentID: String) {
        self.database = database
        self.parentPath = parentPath
        self.documentID = documentID
    }
    
    init(name: String) {
        let components = name
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        let projectID = String(components[1])
        let databaseID = String(components[3])
        let database = Database(projectId: projectID, databaseId: databaseID)
        let pathCompoennts = components[5...]
        let parentPath = pathCompoennts.dropLast(1).joined(separator: "/")
        let documentID = String(pathCompoennts.last!)
        self.init(database, parentPath: parentPath, documentID: documentID)
    }
    
    public var parent: CollectionReference {
        let components = parentPath
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        let parentPath = components.dropLast(1).joined(separator: "/")
        let collectionID = String(components.last!)
        return CollectionReference(database, parentPath: parentPath, collectionID: collectionID)
    }
    
    public func collection(_ collectionID: String) -> CollectionReference {
        if collectionID.isEmpty {
            fatalError("Collection ID cannot be empty.")
        }
        let components = collectionID
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        if components.count.isMultiple(of: 2) {
            fatalError("Invalid collection ID. \(collectionID).")
        }
        return CollectionReference(database, parentPath: path, collectionID: collectionID)
    }
    
    public func getDocument<Transport: ClientTransport>(firestore: Firestore<Transport>) async throws -> DocumentSnapshot {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await getDocument(firestore: firestore, metadata: metadata)
    }

    public func setData<Transport: ClientTransport>(_ documentData: [String: Any], merge: Bool = false, firestore: Firestore<Transport>) async throws {
        print("[FirebaseAPI.DocumentReference] 📝 Wrapper setData (no metadata param) called")
        print("[FirebaseAPI.DocumentReference] 📝 Getting access token from firestore...")
        guard let accessToken = try await firestore.getAccessToken() else {
            print("[FirebaseAPI.DocumentReference] ❌ AccessToken is empty!")
            fatalError("AccessToken is empty")
        }
        print("[FirebaseAPI.DocumentReference] ✅ AccessToken obtained in wrapper: \(accessToken.prefix(20))...")
        print("[FirebaseAPI.DocumentReference] 📝 Creating metadata with Bearer token...")
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        print("[FirebaseAPI.DocumentReference] ✅ Metadata created")
        print("[FirebaseAPI.DocumentReference] 📝 Calling setData with metadata parameter...")
        try await setData(documentData, merge: merge, firestore: firestore, metadata: metadata)
        print("[FirebaseAPI.DocumentReference] ✅ Wrapper setData completed")
    }

    public func updateData<Transport: ClientTransport>(_ fields: [String: Any], firestore: Firestore<Transport>) async throws {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        try await updateData(fields, firestore: firestore, metadata: metadata)
    }

    public func delete<Transport: ClientTransport>(firestore: Firestore<Transport>) async throws {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        try await delete(firestore: firestore, metadata: metadata)
    }

    public func getDocument<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>) async throws -> T? {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await getDocument(type: type, firestore: firestore, metadata: metadata)
    }

    public func setData<T: Encodable, Transport: ClientTransport>(_ data: T, merge: Bool = false, firestore: Firestore<Transport>) async throws {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        try await setData(data, merge: merge, firestore: firestore, metadata: metadata)
    }

    public func updateData<T: Encodable, Transport: ClientTransport>(_ fields: T, firestore: Firestore<Transport>) async throws {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        try await updateData(fields, firestore: firestore, metadata: metadata)
    }

    public func addSnapshotListener<Transport: ClientTransport>(firestore: Firestore<Transport>) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await addSnapshotListener(firestore: firestore, metadata: metadata)
    }
}

extension DocumentReference: Hashable {
    public static func == (lhs: DocumentReference, rhs: DocumentReference) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension DocumentReference: Codable {
    enum CodingKeys: CodingKey {
        case database
        case path
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(database.database, forKey: .database)
        try container.encode(path, forKey: .path)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let database = try container.decode(Database.self, forKey: .database)
        let path = try container.decode(String.self, forKey: .path)
        let components = path
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        let documentID = String(components.last!)
        let parentPath = components.dropLast(0).joined(separator: "/")
        self.init(database, parentPath: parentPath, documentID: documentID)
    }
}
