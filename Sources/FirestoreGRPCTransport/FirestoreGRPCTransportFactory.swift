import Foundation
import FirestoreAuthCore
import FirestoreCore
import FirestoreRuntimeConfig
import FirestoreRuntimeSupport
import GRPCCore
import GRPCNIOTransportHTTP2

package struct FirestoreGRPCTransportRuntime: Sendable {
    package let database: Database
    package let referenceRuntime: any FirestoreReferenceRuntime
    package let collectionGroupRuntime: any FirestoreCollectionGroupRuntime
    package let batchWriteRuntime: any FirestoreBatchWriteRuntime
    package let pipelineRuntime: any FirestorePipelineRuntime
    package let transactionRuntime: any FirestoreTransactionRuntime
    package let setLogLevel: @Sendable (FirestoreLogLevel) -> Void
    package let shutdown: @Sendable () async -> Void

    package init(
        database: Database,
        referenceRuntime: any FirestoreReferenceRuntime,
        collectionGroupRuntime: any FirestoreCollectionGroupRuntime,
        batchWriteRuntime: any FirestoreBatchWriteRuntime,
        pipelineRuntime: any FirestorePipelineRuntime,
        transactionRuntime: any FirestoreTransactionRuntime,
        setLogLevel: @escaping @Sendable (FirestoreLogLevel) -> Void,
        shutdown: @escaping @Sendable () async -> Void
    ) {
        self.database = database
        self.referenceRuntime = referenceRuntime
        self.collectionGroupRuntime = collectionGroupRuntime
        self.batchWriteRuntime = batchWriteRuntime
        self.pipelineRuntime = pipelineRuntime
        self.transactionRuntime = transactionRuntime
        self.setLogLevel = setLogLevel
        self.shutdown = shutdown
    }
}

package enum FirestoreGRPCTransportFactory {
    package static func make(
        projectId: String,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings(),
        accessTokenProvider: (any AccessTokenProvider & Sendable)? = nil
    ) throws -> FirestoreGRPCTransportRuntime {
        try settings.validateAuthenticationBoundary(hasAccessTokenProvider: accessTokenProvider != nil)
        let transportSecurity: HTTP2ClientTransport.Posix.TransportSecurity = settings.usesSSL ? .tls : .plaintext
        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: settings.host, port: settings.port),
            transportSecurity: transportSecurity
        )
        return make(
            projectId: projectId,
            databaseId: databaseId,
            transport: transport,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
    }

    package static func make<Transport: ClientTransport>(
        projectId: String,
        databaseId: String = "(default)",
        transport: Transport,
        settings: FirestoreSettings = FirestoreSettings(),
        accessTokenProvider: (any AccessTokenProvider & Sendable)? = nil
    ) -> FirestoreGRPCTransportRuntime {
        let firestore = FirestoreGRPCRuntime(
            projectId: projectId,
            databaseId: databaseId,
            transport: transport,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
        return FirestoreGRPCTransportRuntime(
            database: firestore.database,
            referenceRuntime: firestore,
            collectionGroupRuntime: firestore,
            batchWriteRuntime: firestore,
            pipelineRuntime: firestore,
            transactionRuntime: firestore,
            setLogLevel: { level in
                firestore.setLogLevel(level)
            },
            shutdown: {
                await firestore.shutdown()
            }
        )
    }
}
