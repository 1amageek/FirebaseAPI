import Foundation
import FirestorePipeline
import FirestoreRuntimeConfig
import FirestoreRuntimeSupport
import Synchronization
import Testing
@testable import FirestoreAPI
@testable import FirestoreAdmin

@Suite("FirestoreAdmin API Tests")
struct FirestoreAdminTests {
    @Test("FirestoreAdmin creates runtime-bound references")
    func testFirestoreAdminCreatesRuntimeBoundReferences() throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        let document = try firestore.document("users/user123")
        let collection = try firestore.collection("users")
        let query = collection.whereField("active", isEqualTo: true)
        let collectionGroupQuery = try firestore
            .collectionGroup("posts")
            .whereField("published", isEqualTo: true)

        #expect(document.path == "users/user123")
        #expect(document.runtime != nil)
        #expect(collection.runtime != nil)
        #expect(query.runtime != nil)
        #expect(collectionGroupQuery.runtime != nil)
    }

    @Test("FirestoreAdmin SDK-compatible reference methods validate paths")
    func testFirestoreAdminSDKCompatibleReferenceMethodsValidatePaths() throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        let document = try firestore.document("users/user123")
        let collection = try firestore.collection("users")
        let nestedCollection = try document.collection("posts")
        let generatedDocument = try collection.document()
        let collectionGroup = try firestore.collectionGroup("posts")

        #expect(document.path == "users/user123")
        #expect(collection.path == "users")
        #expect(nestedCollection.path == "users/user123/posts")
        #expect(generatedDocument.path.hasPrefix("users/"))
        #expect(collectionGroup.groupID == "posts")
    }

    @Test("FirestoreAdmin batch is not generic")
    func testFirestoreAdminBatchIsNotGeneric() {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        let batch: FirestoreAdminWriteBatch = firestore.batch()

        #expect(type(of: batch) == FirestoreAdminWriteBatch.self)
    }

    @Test("FirestoreAdmin bulk writer is not generic")
    func testFirestoreAdminBulkWriterIsNotGeneric() {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        let bulkWriter: FirestoreAdminBulkWriter = firestore.bulkWriter()

        #expect(type(of: bulkWriter) == FirestoreAdminBulkWriter.self)
    }

    @Test("FirestoreAdmin conforms to the server-side client protocol")
    func testFirestoreAdminConformsToServerSideClientProtocol() throws {
        let firestore: any FirestoreAdminClient = FirestoreAdmin(
            projectId: "test",
            transport: MockClientTransport()
        )

        let collection = try firestore.collection("users")
        let document = try firestore.document("users/user123")
        let batch = firestore.batch()
        let bulkWriter = firestore.bulkWriter()
        let pipeline = firestore.pipeline().collection("users")

        #expect(collection.path == "users")
        #expect(document.path == "users/user123")
        #expect(type(of: batch) == FirestoreAdminWriteBatch.self)
        #expect(type(of: bulkWriter) == FirestoreAdminBulkWriter.self)
        #expect(pipeline.stages.map(\.name) == ["collection"])
    }

    @Test("FirestoreAdmin batch supports SDK-compatible write methods")
    func testFirestoreAdminBatchSupportsSDKCompatibleWriteMethods() async throws {
        let firestore = FirestoreAdmin(projectId: "expected-project", transport: MockClientTransport())
        let reference = try firestore.document("users/user123")
        let otherReference = DocumentReference(
            Database(projectId: "actual-project"),
            parentPath: "users",
            documentID: "user456"
        )
        let batch = firestore.batch()
        _ = try batch
            .setData(["name": "Ada"], forDocument: reference)
            .setData(
                ["profile": ["name": "Ada"]],
                forDocument: reference,
                mergeFields: [FieldPath("profile", "name")]
            )
            .updateData(["active": true], forDocument: reference)
            .deleteDocument(otherReference)

        var didThrowDatabaseMismatch = false
        do {
            try await batch.commit()
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            didThrowDatabaseMismatch = expected == "projects/expected-project/databases/(default)"
                && actual == "projects/actual-project/databases/(default)"
        } catch {
            didThrowDatabaseMismatch = false
        }

        #expect(didThrowDatabaseMismatch)
    }

    @Test("FirestoreAdmin bulk writer validates server-side BatchWrite constraints")
    func testFirestoreAdminBulkWriterValidatesServerSideBatchWriteConstraints() async throws {
        let firestore = FirestoreAdmin(projectId: "expected-project", transport: MockClientTransport())
        let reference = try firestore.document("users/user123")
        let otherReference = DocumentReference(
            Database(projectId: "actual-project"),
            parentPath: "users",
            documentID: "user456"
        )

        let mismatchWriter = firestore.bulkWriter()
        mismatchWriter
            .setData(["name": "Ada"], forDocument: reference)
            .deleteDocument(otherReference)

        var didThrowDatabaseMismatch = false
        do {
            _ = try await mismatchWriter.flush()
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            didThrowDatabaseMismatch = expected == "projects/expected-project/databases/(default)"
                && actual == "projects/actual-project/databases/(default)"
        } catch {
            didThrowDatabaseMismatch = false
        }

        let duplicateWriter = firestore.bulkWriter()
        duplicateWriter
            .setData(["name": "Ada"], forDocument: reference)
            .deleteDocument(reference)

        var didThrowDuplicateDocument = false
        do {
            _ = try await duplicateWriter.flush()
        } catch FirestoreError.invalidOperation(let message) {
            didThrowDuplicateDocument = message.contains("same document")
        } catch {
            didThrowDuplicateDocument = false
        }

        #expect(didThrowDatabaseMismatch)
        #expect(didThrowDuplicateDocument)
    }

    @Test("FirestoreAdmin transaction is not generic")
    func testFirestoreAdminTransactionIsNotGeneric() {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        let transaction = FirestoreAdminTransaction(
            database: firestore.database,
            runtime: firestore.transactionRuntime
        )

        #expect(type(of: transaction) == FirestoreAdminTransaction.self)
    }

    @Test("FirestoreAdmin transaction retries aborted commit with retry transaction ID")
    func testFirestoreAdminTransactionRetriesAbortedCommitWithRetryTransactionID() async throws {
        let runtime = TransactionRetryRuntime()
        let firestore = FirestoreAdmin(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { _ in }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )
        let reference = try firestore.document("users/user123")

        let result = try await firestore.runTransaction { transaction -> Int? in
            try transaction
                .create(from: FirestoreAdminTestUser(name: "Ada"), forDocument: reference)
                .setData(from: FirestoreAdminTestUser(name: "Ada"), forDocument: reference, merge: true)
                .updateData(from: FirestoreAdminTestUser(name: "Ada"), forDocument: reference)
            return 42
        }
        let state = runtime.snapshot()

        #expect(result == 42)
        #expect(state.beginRetryTransactionIDs == [nil, Data([1])])
        #expect(state.commitTransactionIDs == [Data([1]), Data([2])])
        #expect(state.rollbackTransactionIDs.isEmpty)
    }

    @Test("FirestoreAdmin transaction clears writes between retry attempts")
    func testFirestoreAdminTransactionClearsWritesBetweenRetryAttempts() async throws {
        let runtime = TransactionRetryRuntime()
        let firestore = FirestoreAdmin(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { _ in }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )
        let firstReference = try firestore.document("users/first")
        let secondReference = try firestore.document("users/second")
        let attemptCounter = Mutex(0)

        let result = try await firestore.runTransaction { transaction -> Int? in
            let attempt = attemptCounter.withLock { count in
                count += 1
                return count
            }
            let reference = attempt == 1 ? firstReference : secondReference
            transaction.setData(["attempt": attempt], forDocument: reference)
            return attempt
        }
        let state = runtime.snapshot()

        #expect(result == 2)
        #expect(state.commitWriteCounts == [1, 1])
        #expect(state.commitWriteDocumentPaths == [["users/first"], ["users/second"]])
    }

    @Test("FirestoreAdmin transaction decodes typed reads")
    func testFirestoreAdminTransactionDecodesTypedReads() async throws {
        struct User: Codable, Equatable {
            @DocumentID var id: String
            var name: String
            var embedding: FirestoreVector
        }

        let runtime = TransactionRetryRuntime()
        let firestore = FirestoreAdmin(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { _ in }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )
        let reference = try firestore.document("users/user123")
        runtime.setReadSnapshots(
            documents: [
                DocumentSnapshot(
                    fields: [
                        "name": .string("Ada"),
                        "embedding": .array([.double(1.0), .double(2.0)])
                    ],
                    documentReference: reference
                )
            ],
            query: QuerySnapshot(
                documents: [
                    QueryDocumentSnapshot(
                        fields: [
                            "name": .string("Grace"),
                            "embedding": .array([.double(3.0), .double(4.0)])
                        ],
                        documentReference: try firestore.document("users/user456")
                    )
                ]
            )
        )

        let result = try await firestore.runTransaction({ transaction -> ([User], [User])? in
            let document = try await transaction.getDocument(reference, type: User.self)
            let queryDocuments = try await transaction.get(
                query: try firestore.collection("users").toQuery(),
                type: User.self
            )
            return ([document].compactMap { $0 }, queryDocuments)
        }, options: TransactionOptions(readOnly: true))
        let state = runtime.snapshot()

        #expect(result?.0 == [User(id: "user123", name: "Ada", embedding: FirestoreVector([1.0, 2.0]))])
        #expect(result?.1 == [User(id: "user456", name: "Grace", embedding: FirestoreVector([3.0, 4.0]))])
        #expect(state.batchGetTransactionIDs == [Data([1])])
        #expect(state.runQueryTransactionIDs == [Data([1])])
    }

    @Test("FirestoreAdmin read-only transaction skips commit")
    func testFirestoreAdminReadOnlyTransactionSkipsCommit() async throws {
        let runtime = TransactionRetryRuntime()
        let firestore = FirestoreAdmin(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { _ in }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )
        let reference = try firestore.document("users/user123")

        let result = try await firestore.runTransaction({ transaction -> Int? in
            _ = try await transaction.getAll(documentReferences: reference)
            return 7
        }, options: TransactionOptions(readOnly: true))
        let state = runtime.snapshot()

        #expect(result == 7)
        #expect(state.beginReadOnlyFlags == [true])
        #expect(state.beginRetryTransactionIDs == [nil])
        #expect(state.commitTransactionIDs.isEmpty)
        #expect(state.rollbackTransactionIDs.isEmpty)
    }

    @Test("FirestoreAdmin read-only transaction rejects writes without commit")
    func testFirestoreAdminReadOnlyTransactionRejectsWritesWithoutCommit() async throws {
        let runtime = TransactionRetryRuntime()
        let firestore = FirestoreAdmin(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { _ in }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )
        let reference = try firestore.document("users/user123")

        var didThrowReadOnlyWrite = false
        do {
            let _: Int? = try await firestore.runTransaction({ transaction in
                transaction.setData(["name": "Ada"], forDocument: reference)
                return 1
            }, options: TransactionOptions(readOnly: true))
        } catch FirestoreError.readOnlyTransactionWrite {
            didThrowReadOnlyWrite = true
        } catch {
            didThrowReadOnlyWrite = false
        }
        let state = runtime.snapshot()

        #expect(didThrowReadOnlyWrite)
        #expect(state.beginReadOnlyFlags == [true])
        #expect(state.commitTransactionIDs.isEmpty)
        #expect(state.rollbackTransactionIDs == [Data([1])])
    }

    @Test("FirestoreAdmin transaction wraps rollback failure")
    func testFirestoreAdminTransactionWrapsRollbackFailure() async throws {
        let runtime = TransactionRetryRuntime(rollbackShouldFail: true)
        let firestore = FirestoreAdmin(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { _ in }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )

        var didWrapRollbackFailure = false
        do {
            _ = try await firestore.runTransaction { _ -> Int? in
                throw FirestoreError.invalidOperation("transaction body failed")
            }
            Issue.record("Expected rollback failure to throw.")
        } catch FirestoreError.transactionFailed(let error) {
            if case TransactionError.rollbackFailed(let original, let rollback) = error {
                didWrapRollbackFailure = true
                #expect((original as? FirestoreError)?.remoteErrorCode == nil)
                #expect((rollback as? FirestoreError)?.remoteErrorCode == .internalError)
            }
        } catch TransactionError.rollbackFailed {
            didWrapRollbackFailure = false
        } catch {
            Issue.record("Expected transactionFailed error, got \(error).")
        }

        let state = runtime.snapshot()
        #expect(didWrapRollbackFailure)
        #expect(state.rollbackTransactionIDs == [Data([1])])
    }

    @Test("FirestoreAdmin batch commit throws typed access token error")
    func testFirestoreAdminBatchCommitThrowsTypedAccessTokenError() async throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())
        let reference = try firestore.document("users/user123")
        let batch = firestore.batch()
        batch.setData(["name": "Ada"], forDocument: reference)

        var didThrowInvalidAccessToken = false
        do {
            try await batch.commit()
        } catch FirestoreError.invalidAccessToken(_) {
            didThrowInvalidAccessToken = true
        } catch {
            didThrowInvalidAccessToken = false
        }

        #expect(didThrowInvalidAccessToken)
    }

    @Test("FirestoreAdmin batch rejects repeated commit")
    func testFirestoreAdminBatchRejectsRepeatedCommit() async throws {
        let database = Database(projectId: "test")
        let recorder = BatchCommitRecorder()
        let reference = DocumentReference(database, parentPath: "users", documentID: "user123")
        let batch = FirestoreAdminWriteBatch(database: database) { _ in
            await recorder.record()
        }
        batch.setData(["name": "Ada"], forDocument: reference)

        try await batch.commit()

        var didThrowInvalidOperation = false
        do {
            try await batch.commit()
        } catch FirestoreError.invalidOperation(let message) {
            didThrowInvalidOperation = message == "Write batch has already been committed."
        } catch {
            didThrowInvalidOperation = false
        }

        #expect(didThrowInvalidOperation)
        #expect(await recorder.snapshot() == 1)
    }

    @Test("FirestoreAdmin maps gRPC errors to Firestore error codes")
    func testFirestoreAdminMapsGRPCErrorsToFirestoreErrorCodes() async throws {
        let firestore = FirestoreAdmin(
            projectId: "test",
            transport: MockClientTransport(),
            accessTokenProvider: StaticAccessTokenProvider()
        )
        let reference = try firestore.document("users/user123")
        let batch = firestore.batch()
        batch.setData(["name": "Ada"], forDocument: reference)

        var didThrowUnimplemented = false
        var thrownError: Error?
        do {
            try await batch.commit()
        } catch FirestoreError.rpcError(let error) {
            didThrowUnimplemented = error.code == .unimplemented
                && error.message == "MockClientTransport is for testing only"
            if !didThrowUnimplemented {
                thrownError = FirestoreError.rpcError(error)
            }
        } catch {
            thrownError = error
            didThrowUnimplemented = false
        }

        #expect(
            didThrowUnimplemented,
            "Expected unimplemented MockClientTransport RPC error, got \(String(describing: thrownError))."
        )
    }

    @Test("FirestoreAdmin emulator settings disable authentication")
    func testFirestoreAdminEmulatorSettingsDisableAuthentication() async throws {
        let settings = FirestoreSettings.emulator(host: "127.0.0.1", port: 8080)
        let firestore = FirestoreAdmin(
            projectId: "test",
            transport: MockClientTransport(),
            settings: settings
        )
        let reference = try firestore.document("users/user123")
        let batch = firestore.batch()
        batch.setData(["name": "Ada"], forDocument: reference)

        var didReachTransport = false
        do {
            try await batch.commit()
        } catch FirestoreError.rpcError(let error) {
            didReachTransport = error.code == .unimplemented
                && settings.authenticationMode == .disabled
                && !settings.usesSSL
        } catch {
            didReachTransport = false
        }

        #expect(didReachTransport)
    }

    @Test("FirestoreAdmin validates server-side authentication settings before transport startup")
    func testFirestoreAdminValidatesServerSideAuthenticationSettingsBeforeTransportStartup() throws {
        do {
            _ = try FirestoreAdmin(projectId: "test")
            Issue.record("Expected missing access token provider configuration error")
        } catch FirestoreError.invalidConfiguration(let message) {
            #expect(message.contains("Firestore authentication is required"))
        }

        do {
            _ = try FirestoreAdmin(
                projectId: "test",
                settings: FirestoreSettings(authenticationMode: .disabled)
            )
            Issue.record("Expected disabled authentication configuration error")
        } catch FirestoreError.invalidConfiguration(let message) {
            #expect(message.contains("Disabled Firestore authentication is only supported"))
        }
    }

    @Test("FirestoreSettings allows disabled authentication only for emulator settings")
    func testFirestoreSettingsAllowsDisabledAuthenticationOnlyForEmulatorSettings() throws {
        let emulatorSettings = FirestoreSettings.emulator(host: "127.0.0.1", port: 8080)
        try emulatorSettings.validateAuthenticationBoundary(hasAccessTokenProvider: false)

        var invalidGoogleAPISettings = FirestoreSettings.emulator(
            host: "firestore.googleapis.com",
            port: 443
        )
        invalidGoogleAPISettings.usesSSL = false

        do {
            try invalidGoogleAPISettings.validateAuthenticationBoundary(hasAccessTokenProvider: false)
            Issue.record("Expected Google APIs host rejection for disabled authentication")
        } catch FirestoreError.invalidConfiguration(let message) {
            #expect(message.contains("Google APIs hosts"))
        }
    }

    private struct StaticAccessTokenProvider: AccessTokenProvider {
        let scope: any AccessScope = FirestoreAccessScope.datastore

        func getAccessToken(expirationDuration: TimeInterval) async throws -> String {
            "test-token"
        }
    }

    @Test("FirestoreAdmin batch commit throws database mismatch")
    func testFirestoreAdminBatchCommitThrowsDatabaseMismatch() async {
        let firestore = FirestoreAdmin(projectId: "expected-project", transport: MockClientTransport())
        let otherReference = DocumentReference(
            Database(projectId: "actual-project"),
            parentPath: "users",
            documentID: "user123"
        )
        let batch = firestore.batch()
        batch.setData(["name": "Ada"], forDocument: otherReference)

        var didThrowDatabaseMismatch = false
        do {
            try await batch.commit()
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            didThrowDatabaseMismatch = expected == "projects/expected-project/databases/(default)"
                && actual == "projects/actual-project/databases/(default)"
        } catch {
            didThrowDatabaseMismatch = false
        }

        #expect(didThrowDatabaseMismatch)
    }

    @Test("FirestoreAdmin reference creation throws invalid path")
    func testFirestoreAdminReferenceCreationThrowsInvalidPath() {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        var didThrowInvalidPath = false
        do {
            _ = try firestore.document("users")
        } catch FirestoreError.invalidPath(_) {
            didThrowInvalidPath = true
        } catch {
            didThrowInvalidPath = false
        }

        #expect(didThrowInvalidPath)
    }

    @Test("FirestoreAdmin reference creation rejects empty path segments")
    func testFirestoreAdminReferenceCreationRejectsEmptyPathSegments() throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())
        let collection = try firestore.collection("users")
        let document = try firestore.document("users/user123")

        #expect(throws: FirestoreError.self) {
            _ = try firestore.collection("/users")
        }
        #expect(throws: FirestoreError.self) {
            _ = try firestore.collection("users/")
        }
        #expect(throws: FirestoreError.self) {
            _ = try firestore.collection("users/user123//posts")
        }
        #expect(throws: FirestoreError.self) {
            _ = try firestore.document("/users/user123")
        }
        #expect(throws: FirestoreError.self) {
            _ = try firestore.document("users//user123")
        }
        #expect(throws: FirestoreError.self) {
            _ = try firestore.document("users/user123/")
        }
        #expect(throws: FirestoreError.self) {
            _ = try collection.document("/user456")
        }
        #expect(throws: FirestoreError.self) {
            _ = try collection.document("user456/")
        }
        #expect(throws: FirestoreError.self) {
            _ = try document.collection("posts//comments")
        }
    }
}

private struct FirestoreAdminTestUser: Encodable {
    var name: String
}

private actor BatchCommitRecorder {
    private var count = 0

    func record() {
        count += 1
    }

    func snapshot() -> Int {
        count
    }
}

private final class TransactionRetryRuntime: FirestoreRuntime, FirestoreTransactionRuntime {
    struct State: Sendable {
        var beginReadOnlyFlags: [Bool] = []
        var beginRetryTransactionIDs: [Data?] = []
        var batchGetTransactionIDs: [Data?] = []
        var runQueryTransactionIDs: [Data?] = []
        var commitTransactionIDs: [Data?] = []
        var commitWriteCounts: [Int] = []
        var commitWriteDocumentPaths: [[String]] = []
        var rollbackTransactionIDs: [Data] = []
        var documentSnapshots: [DocumentSnapshot] = []
        var querySnapshot = QuerySnapshot(documents: [])
    }

    let runtimeDatabase = Database(projectId: "test")
    private let state = Mutex(State())
    private let rollbackShouldFail: Bool

    init(rollbackShouldFail: Bool = false) {
        self.rollbackShouldFail = rollbackShouldFail
    }

    func snapshot() -> State {
        state.withLock { $0 }
    }

    func setReadSnapshots(documents: [DocumentSnapshot], query: QuerySnapshot) {
        state.withLock {
            $0.documentSnapshots = documents
            $0.querySnapshot = query
        }
    }

    func beginTransactionID(readOnly: Bool, readTime: Timestamp?, retryTransactionID: Data?) async throws -> Data {
        state.withLock { state in
            state.beginReadOnlyFlags.append(readOnly)
            state.beginRetryTransactionIDs.append(retryTransactionID)
            return Data([UInt8(state.beginRetryTransactionIDs.count)])
        }
    }

    func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?) async throws -> [DocumentSnapshot] {
        state.withLock {
            $0.batchGetTransactionIDs.append(transactionID)
            return $0.documentSnapshots
        }
    }

    func runQuery(query: Query, transactionID: Data?) async throws -> QuerySnapshot {
        state.withLock {
            $0.runQueryTransactionIDs.append(transactionID)
            return $0.querySnapshot
        }
    }

    func commitWrites(_ writes: [WriteData], transactionID: Data?) async throws -> Bool {
        let commitCount = state.withLock { state in
            state.commitTransactionIDs.append(transactionID)
            state.commitWriteCounts.append(writes.count)
            state.commitWriteDocumentPaths.append(writes.map(\.documentReference.path))
            return state.commitTransactionIDs.count
        }
        if commitCount == 1 {
            throw FirestoreError.rpcError(
                FirestoreRemoteError(code: .aborted, message: "transaction aborted")
            )
        }
        return true
    }

    func rollbackTransactionID(transactionID: Data) async throws {
        state.withLock { $0.rollbackTransactionIDs.append(transactionID) }
        if rollbackShouldFail {
            throw FirestoreError.rpcError(
                FirestoreRemoteError(code: .internalError, message: "rollback failed")
            )
        }
    }

    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        DocumentSnapshot(documentReference: reference)
    }

    func setData(_ data: [String: Any], merge: Bool, for reference: DocumentReference) async throws {}

    func setData(_ data: [String: Any], mergeFields: [String], for reference: DocumentReference) async throws {}

    func updateData(_ fields: [String: Any], for reference: DocumentReference) async throws {}

    func deleteDocument(_ reference: DocumentReference) async throws {}

    func listCollections(in reference: DocumentReference) async throws -> [CollectionReference] {
        []
    }

    func listen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func getDocuments(for query: Query) async throws -> QuerySnapshot {
        QuerySnapshot(documents: [])
    }

    func listen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func aggregate(_ query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        AggregateQuerySnapshot(data: [:])
    }

    func explain(_ query: Query, options: FirestoreExplainOptions) async throws -> QueryExplainResult {
        QueryExplainResult(
            snapshot: nil,
            metrics: FirestoreExplainMetrics(
                planSummary: FirestoreExplainPlanSummary(indexesUsed: []),
                executionStats: nil
            )
        )
    }

    func explainAggregation(
        _ query: Query,
        fields: [AggregateField],
        options: FirestoreExplainOptions
    ) async throws -> AggregateQueryExplainResult {
        AggregateQueryExplainResult(
            snapshot: nil,
            metrics: FirestoreExplainMetrics(
                planSummary: FirestoreExplainPlanSummary(indexesUsed: []),
                executionStats: nil
            )
        )
    }

    func executePipeline(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        PipelineQuerySnapshot(rows: [], executionTime: nil)
    }

    func explainPipeline(_ pipeline: FirestorePipeline, options: PipelineExplainOptions) async throws -> PipelineExplainResult {
        PipelineExplainResult(
            snapshot: nil,
            stats: PipelineExplainStats(
                outputFormat: options.outputFormat,
                text: nil,
                json: nil,
                rawTypeURL: nil,
                rawData: nil
            )
        )
    }
}
