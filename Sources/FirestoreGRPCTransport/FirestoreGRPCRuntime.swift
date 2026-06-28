import Foundation
import FirestoreRPC
import FirestoreAuthCore
import FirestoreCore
import FirestoreRuntimeConfig
import GRPCCore
import Logging
import Synchronization

package final class FirestoreGRPCRuntime<Transport: ClientTransport>: Sendable {
    package let database: Database
    internal let transport: Transport
    internal let settings: FirestoreSettings
    private let logger: Mutex<Logger>
    internal let grpcClient: GRPCClient<Transport>
    internal let listenTargetIDGenerator = ListenTargetIDGenerator()
    private let connectionTask: Task<Void, Never>

    let accessTokenProvider: (any AccessTokenProvider & Sendable)?

    package init(
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
        let grpcClient = GRPCClient(transport: transport)
        self.grpcClient = grpcClient
        var logger = Logger(label: "com.firestore.\(projectId)")
        logger.logLevel = settings.logLevel.toLoggerLevel()
        self.logger = Mutex(logger)

        let connectionLogger = logger
        self.connectionTask = Task {
            do {
                connectionLogger.info("Starting gRPC connections...")
                try await grpcClient.runConnections()
                connectionLogger.info("gRPC connections completed")
            } catch let error as RuntimeError where error.code == .clientIsStopped {
                connectionLogger.debug("gRPC connections stopped before startup completed: \(error)")
            } catch {
                connectionLogger.error("Failed to run gRPC connections: \(error)")
            }
        }
    }

    package func setLogLevel(_ level: FirestoreLogLevel) {
        logger.withLock { logger in
            logger.logLevel = level.toLoggerLevel()
        }
    }

    internal func getAccessToken() async throws -> String? {
        try await accessTokenProvider?.getAccessToken(expirationDuration: 3600)
    }

    internal func nextListenTargetID() -> Int32 {
        listenTargetIDGenerator.next()
    }

    package func shutdown() async {
        grpcClient.beginGracefulShutdown()
        await connectionTask.value
    }
}
