import Foundation
import GRPC
import NIO
import SwiftProtobuf
import Logging
import NIOSSL

public final class Firestore {
    
    internal var database: Database
    internal var channel: ClientConnection
    internal var settings: FirestoreSettings
    internal var logger: FirestoreLogger
    
    public var accessTokenProvider: (any AccessTokenProvider)?
    
    private let eventLoopGroup: EventLoopGroup
    
    public init(
        projectId: String,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings()
    ) {
        self.database = Database(projectId: projectId, databaseId: databaseId)
        self.settings = settings
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        if settings.usesSSL {
            self.channel = ClientConnection.usingTLSBackedByNIOSSL(on: eventLoopGroup)
                .withConnectionTimeout(minimum: settings.timeout)
                .connect(host: settings.host, port: settings.port)
        } else {
            self.channel = ClientConnection.insecure(group: eventLoopGroup)
                .withConnectionTimeout(minimum: settings.timeout)
                .connect(host: settings.host, port: settings.port)
        }
        
        self.logger = FirestoreLogger(
            label: "com.firestore.\(projectId)",
            logLevel: settings.logLevel
        )
    }
    
    deinit {
        try? self.eventLoopGroup.syncShutdownGracefully()
    }
    
    public func collectionGroup(_ groupID: String) -> CollectionGroup {
        if groupID.isEmpty {
            fatalError("Group ID cannot be empty.")
        }
        if groupID.contains("/") {
            fatalError("Invalid collection ID \(groupID). Collection IDs must not contain / in them.")
        }
        return CollectionGroup(database, groupID: groupID)
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
        let parentPath = components.dropLast(1).joined(separator: "/")
        let collectionID = String(components.last!)
        return CollectionReference(database, parentPath: parentPath, collectionID: collectionID)
    }
    
    public func document(_ documentID: String) -> DocumentReference {
        if documentID.isEmpty {
            fatalError("Document path cannot be empty.")
        }
        let components = documentID
            .split(separator: "/")
            .filter({ !$0.isEmpty })
        if !components.count.isMultiple(of: 2) {
            fatalError("Invalid path. \(documentID).")
        }
        let parentPath = components.dropLast(1).joined(separator: "/")
        let documentID = String(components.last!)
        return DocumentReference(database, parentPath: parentPath, documentID: documentID)
    }
    
    public func batch() -> WriteBatch {
        return WriteBatch(firestore: self)
    }
    
    public func setLogLevel(_ level: FirestoreLogLevel) {
        self.settings.logLevel = level
        self.logger.setLogLevel(level)
    }
    
    internal func getAccessToken() async throws -> String? {
        return try await accessTokenProvider?.getAccessToken(expirationDuration: 3600)
    }
    
    internal func terminate() {
        try? self.channel.close().wait()
        try? self.eventLoopGroup.syncShutdownGracefully()
    }
}
