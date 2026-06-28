import Foundation
import FirestoreAdmin
import FirestoreAuthCore
import FirestoreAuth
import FirestoreCore
import FirestoreGRPCTransport
import FirestoreRuntimeConfig
import GRPCCore

extension FirestoreAdmin {
    public convenience init(
        projectId: String,
        credentials: ServiceAccountCredentials,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings(),
        scope: any AccessScope = FirestoreAccessScope.datastore
    ) throws {
        let accessTokenProvider = try ServiceAccountAccessTokenProvider(credentials: credentials, scope: scope)
        try self.init(
            projectId: projectId,
            databaseId: databaseId,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
    }

    public convenience init(
        credentials: ServiceAccountCredentials,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings(),
        scope: any AccessScope = FirestoreAccessScope.datastore
    ) throws {
        try self.init(
            projectId: credentials.projectId,
            credentials: credentials,
            databaseId: databaseId,
            settings: settings,
            scope: scope
        )
    }

    public static func applicationDefault(
        projectId: String? = nil,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings(),
        scope: any AccessScope = FirestoreAccessScope.datastore
    ) throws -> FirestoreAdmin {
        let accessTokenProvider = try GoogleApplicationDefaultCredentials.accessTokenProvider(scope: scope)
        let resolvedProjectId: String
        if let projectId {
            resolvedProjectId = projectId
        } else if let defaultProjectId = try GoogleApplicationDefaultCredentials.projectID() {
            resolvedProjectId = defaultProjectId
        } else {
            throw FirestoreError.invalidConfiguration(
                "FirestoreAdmin.applicationDefault requires projectId when Application Default Credentials cannot resolve a project ID synchronously."
            )
        }

        return try FirestoreAdmin(
            projectId: resolvedProjectId,
            databaseId: databaseId,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
    }

    public static func applicationDefaultResolvingProjectID(
        projectId: String? = nil,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings(),
        scope: any AccessScope = FirestoreAccessScope.datastore
    ) async throws -> FirestoreAdmin {
        let accessTokenProvider = try GoogleApplicationDefaultCredentials.accessTokenProvider(scope: scope)
        let resolvedProjectId: String
        if let projectId {
            resolvedProjectId = projectId
        } else if let defaultProjectId = try await GoogleApplicationDefaultCredentials.resolvedProjectID() {
            resolvedProjectId = defaultProjectId
        } else {
            throw FirestoreError.invalidConfiguration(
                "FirestoreAdmin.applicationDefaultResolvingProjectID requires projectId when Application Default Credentials cannot resolve a project ID."
            )
        }

        return try FirestoreAdmin(
            projectId: resolvedProjectId,
            databaseId: databaseId,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
    }

    public static func emulator(
        projectId: String,
        databaseId: String = "(default)",
        host: String = "127.0.0.1",
        port: Int = 8080,
        timeout: Duration = .seconds(30),
        maxRetryAttempts: Int = 5,
        retryStrategy: FirestoreRetryStrategy = .exponentialBackoff(),
        logLevel: FirestoreLogLevel = .info
    ) throws -> FirestoreAdmin {
        try FirestoreAdmin(
            projectId: projectId,
            databaseId: databaseId,
            settings: .emulator(
                host: host,
                port: port,
                timeout: timeout,
                maxRetryAttempts: maxRetryAttempts,
                retryStrategy: retryStrategy,
                logLevel: logLevel
            ),
            accessTokenProvider: nil
        )
    }

    public convenience init(
        projectId: String,
        databaseId: String = "(default)",
        transport: some ClientTransport,
        settings: FirestoreSettings = FirestoreSettings(),
        accessTokenProvider: (any AccessTokenProvider & Sendable)? = nil
    ) {
        let transportRuntime = FirestoreGRPCTransportFactory.make(
            projectId: projectId,
            databaseId: databaseId,
            transport: transport,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
        self.init(transportRuntime: transportRuntime)
    }

    public convenience init(
        projectId: String,
        databaseId: String = "(default)",
        settings: FirestoreSettings = FirestoreSettings(),
        accessTokenProvider: (any AccessTokenProvider & Sendable)? = nil
    ) throws {
        let transportRuntime = try FirestoreGRPCTransportFactory.make(
            projectId: projectId,
            databaseId: databaseId,
            settings: settings,
            accessTokenProvider: accessTokenProvider
        )
        self.init(transportRuntime: transportRuntime)
    }

    package convenience init(transportRuntime: FirestoreGRPCTransportRuntime) {
        let transactionRuntime = transportRuntime.transactionRuntime
        self.init(
            database: transportRuntime.database,
            referenceRuntime: transportRuntime.referenceRuntime,
            collectionGroupRuntime: transportRuntime.collectionGroupRuntime,
            batchWriteRuntime: transportRuntime.batchWriteRuntime,
            pipelineRuntime: transportRuntime.pipelineRuntime,
            transactionRuntime: transactionRuntime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: transportRuntime.database) { writes in
                    let didCommit = try await transactionRuntime.commitWrites(writes, transactionID: nil)
                    guard didCommit else {
                        throw FirestoreError.commitFailed
                    }
                }
            },
            setLogLevelHandler: transportRuntime.setLogLevel,
            shutdownHandler: transportRuntime.shutdown
        )
    }
}
