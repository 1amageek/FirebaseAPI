import Foundation
import GRPCCore
import SwiftProtobuf
import Logging

public final class Firestore<Transport: ClientTransport>: Sendable {

    internal let database: Database
    internal let transport: Transport
    internal let settings: FirestoreSettings
    internal let logger: Logger
    internal let grpcClient: GRPCClient<Transport>

    public let accessTokenProvider: (any AccessTokenProvider & Sendable)?

    public init(
        projectId: String,
        databaseId: String = "(default)",
        transport: Transport,
        settings: FirestoreSettings = FirestoreSettings(),
        accessTokenProvider: (any AccessTokenProvider & Sendable)? = nil
    ) {
        self.database = Database(projectId: projectId, databaseId: databaseId)
        self.transport = transport
        self.settings = settings
        self.accessTokenProvider = accessTokenProvider
        self.grpcClient = GRPCClient(transport: transport)
        var logger = Logger(label: "com.firestore.\(projectId)")
        logger.logLevel = settings.logLevel.toLoggerLevel()
        self.logger = logger

        // Start the gRPC client connections
        let connectionLogger = logger
        Task {
            do {
                connectionLogger.info("Starting gRPC connections...")
                try await self.grpcClient.runConnections()
                connectionLogger.info("gRPC connections completed")
            } catch {
                connectionLogger.error("Failed to run gRPC connections: \(error)")
            }
        }
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
    
    public func batch() -> WriteBatch<Transport> {
        return WriteBatch(firestore: self)
    }
    
    public func setLogLevel(_ level: FirestoreLogLevel) {
        var mutableLogger = self.logger
        mutableLogger.logLevel = level.toLoggerLevel()
    }
    
    internal func getAccessToken() async throws -> String? {
        return try await accessTokenProvider?.getAccessToken(expirationDuration: 3600)
    }
}
