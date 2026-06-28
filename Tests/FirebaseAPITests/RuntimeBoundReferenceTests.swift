import Foundation
import FirestorePipeline
import FirestoreRuntimeSupport
import Synchronization
import Testing
@testable import FirestoreAPI
@testable import FirestoreAdmin
@testable import FirestoreAdminCore

@Suite("Runtime Bound Reference Tests")
struct RuntimeBoundReferenceTests {
    @Test("Firestore-created references keep runtime")
    func testFirestoreCreatedReferencesKeepRuntime() throws {
        let firestore = Firestore(projectId: "test", transport: MockClientTransport())

        let document = try firestore.document("users/user123")
        let collection = try firestore.collection("users")
        let query = collection.whereField("active", isEqualTo: true)
        let collectionGroupQuery = try firestore
            .collectionGroup("posts")
            .whereField("published", isEqualTo: true)

        #expect(document.runtime != nil)
        #expect(try document.collection("posts").runtime != nil)
        #expect(collection.runtime != nil)
        #expect(try collection.document("user123").runtime != nil)
        #expect(query.runtime != nil)
        #expect(collectionGroupQuery.runtime != nil)
    }

    @Test("SDK-compatible methods keep runtime")
    func testSDKCompatibleMethodsKeepRuntime() throws {
        let firestore = Firestore(projectId: "test", transport: MockClientTransport())

        let document = try firestore.document("users/user123")
        let collection = try firestore.collection("users")
        let query = collection.whereField("active", isEqualTo: true)
        let collectionGroupQuery = try firestore
            .collectionGroup("posts")
            .whereField("published", isEqualTo: true)

        #expect(document.runtime != nil)
        #expect(try document.collection("posts").runtime != nil)
        #expect(collection.runtime != nil)
        #expect(try collection.document("user123").runtime != nil)
        #expect(query.runtime != nil)
        #expect(collectionGroupQuery.runtime != nil)
    }

    @Test("DocumentReference delegates operations to bound runtime")
    func testDocumentReferenceDelegatesOperationsToBoundRuntime() async throws {
        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )

        _ = try await reference.getDocument()
        try await reference.setData(["name": "Ada"], merge: true)
        try await reference.setData(["profile": ["name": "Ada"]], mergeFields: ["profile.name"])
        try await reference.updateData(["age": 37])
        let collections = try await reference.listCollections()
        try await reference.delete()

        let state = runtime.snapshot()
        #expect(collections.map(\.collectionID) == ["posts"])
        #expect(state.getDocumentPaths == ["users/user123"])
        #expect(state.setDataPaths == ["users/user123", "users/user123"])
        #expect(state.setDataMergeFlags == [true])
        #expect(state.setDataMergeFields == [["profile.name"]])
        #expect(state.updateDataPaths == ["users/user123"])
        #expect(state.listCollectionPaths == ["users/user123"])
        #expect(state.deleteDocumentPaths == ["users/user123"])
    }

    @Test("SDK-compatible Codable methods delegate to bound runtime")
    func testSDKCompatibleCodableMethodsDelegateToBoundRuntime() async throws {
        struct User: Codable, Equatable {
            @DocumentID var id: String
            var name: String
        }
        struct WriteUser: Codable, Equatable {
            var name: String
        }

        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        runtime.setReadResults(
            documentFields: ["name": .string("Ada")],
            querySnapshot: QuerySnapshot(
                documents: [
                    QueryDocumentSnapshot(
                        fields: ["name": .string("Grace")],
                        documentReference: DocumentReference(
                            runtime.runtimeDatabase,
                            parentPath: "users",
                            documentID: "user456",
                            runtime: runtime
                        )
                    )
                ]
            )
        )

        let document = try await reference.getDocument(as: User.self)
        try await reference.setData(from: WriteUser(name: "Ada"), merge: true)
        try await reference.setData(from: WriteUser(name: "Ada"), mergeFields: ["name"])
        let collectionUsers = try await collection.getDocuments(as: User.self)
        let queryUsers = try await collection
            .whereField("active", isEqualTo: true)
            .getDocuments(as: User.self)

        let state = runtime.snapshot()
        #expect(document == User(id: "user123", name: "Ada"))
        #expect(collectionUsers == [User(id: "user456", name: "Grace")])
        #expect(queryUsers == [User(id: "user456", name: "Grace")])
        #expect(state.getDocumentPaths == ["users/user123"])
        #expect(state.setDataPaths == ["users/user123", "users/user123"])
        #expect(state.setDataMergeFlags == [true])
        #expect(state.setDataMergeFields == [["name"]])
        #expect(state.queryPaths == ["users", "users"])
    }

    @Test("FirestoreSource default and server delegate reads to bound runtime")
    func testFirestoreSourceDefaultAndServerDelegateReadsToBoundRuntime() async throws {
        struct User: Codable, Equatable {
            @DocumentID var id: String
            var name: String
        }

        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        runtime.setReadResults(
            documentFields: ["name": .string("Ada")],
            querySnapshot: QuerySnapshot(
                documents: [
                    QueryDocumentSnapshot(
                        fields: ["name": .string("Grace")],
                        documentReference: DocumentReference(
                            runtime.runtimeDatabase,
                            parentPath: "users",
                            documentID: "user456",
                            runtime: runtime
                        )
                    )
                ]
            )
        )

        _ = try await reference.getDocument(source: .server)
        let document = try await reference.getDocument(as: User.self, source: .default)
        let collectionUsers = try await collection.getDocuments(as: User.self, source: .server)
        let queryUsers = try await collection
            .whereField("active", isEqualTo: true)
            .getDocuments(as: User.self, source: .default)

        let state = runtime.snapshot()
        #expect(document == User(id: "user123", name: "Ada"))
        #expect(collectionUsers == [User(id: "user456", name: "Grace")])
        #expect(queryUsers == [User(id: "user456", name: "Grace")])
        #expect(state.getDocumentPaths == ["users/user123", "users/user123"])
        #expect(state.queryPaths == ["users", "users"])
    }

    @Test("FirestoreSource cache source throws server-side read error")
    func testFirestoreSourceCacheSourceThrowsServerSideReadError() async throws {
        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        let query = collection.whereField("active", isEqualTo: true)

        var documentDidThrow = false
        do {
            _ = try await reference.getDocument(source: .cache)
        } catch FirestoreError.invalidOperation(let message) {
            documentDidThrow = message.contains("Cache-only")
        } catch {
            documentDidThrow = false
        }

        var collectionDidThrow = false
        do {
            _ = try await collection.getDocuments(source: .cache)
        } catch FirestoreError.invalidOperation(let message) {
            collectionDidThrow = message.contains("Cache-only")
        } catch {
            collectionDidThrow = false
        }

        var queryDidThrow = false
        do {
            _ = try await query.getDocuments(source: .cache)
        } catch FirestoreError.invalidOperation(let message) {
            queryDidThrow = message.contains("Cache-only")
        } catch {
            queryDidThrow = false
        }

        let state = runtime.snapshot()
        #expect(documentDidThrow)
        #expect(collectionDidThrow)
        #expect(queryDidThrow)
        #expect(state.getDocumentPaths.isEmpty)
        #expect(state.queryPaths.isEmpty)
    }

    @Test("CollectionReference and Query delegate operations to bound runtime")
    func testCollectionReferenceAndQueryDelegateOperationsToBoundRuntime() async throws {
        let runtime = RecordingRuntime()
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )

        _ = try await collection.addDocument(data: ["name": "Ada"])
        _ = try await collection.getDocuments()
        _ = try await collection.count()
        _ = try await collection
            .whereField("active", isEqualTo: true)
            .limit(to: 10)
            .getDocuments()
        _ = try await collection.explain(options: .analyze)
        _ = try await collection.explainAggregation([.count()], options: .planOnly)

        let state = runtime.snapshot()
        #expect(state.setDataPaths.count == 1)
        #expect(state.queryPaths == ["users", "users"])
        #expect(state.explainQueryPaths == ["users"])
        #expect(state.explainOptions == [.analyze])
        #expect(state.explainAggregationQueryPaths == ["users"])
        #expect(state.explainAggregationOptions == [.planOnly])
        #expect(state.aggregateQueryPaths == ["users"])
        #expect(state.aggregateQueryAllDescendants == [false])
    }

    @Test("Reference listing and partition planning delegate to bound runtime")
    func testReferenceListingAndPartitionPlanningDelegateToBoundRuntime() async throws {
        let runtime = RecordingRuntime()
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        let collectionGroup = CollectionGroup(
            runtime.runtimeDatabase,
            groupID: "posts",
            runtime: runtime
        )
        let readTime = Timestamp(seconds: 123, nanos: 456)

        let documents = try await collection.listDocuments(pageSize: 25, readTime: readTime)
        let partitions = try await collectionGroup.partitionedQueries(
            partitionPointCount: 3,
            pageSize: 10,
            readTime: readTime
        )

        let state = runtime.snapshot()
        #expect(documents.map(\.path) == ["users/user123", "users/user456"])
        #expect(documents.map { $0.runtime != nil } == [true, true])
        #expect(partitions.map(\.path) == ["posts"])
        #expect(partitions.map(\.allDescendants) == [true])
        #expect(partitions.map { $0.runtime != nil } == [true])
        #expect(state.listDocumentCollectionPaths == ["users"])
        #expect(state.listDocumentPageSizes == [25])
        #expect(state.listDocumentReadTimes == [readTime])
        #expect(state.partitionCollectionGroupIDs == ["posts"])
        #expect(state.partitionPointCounts == [3])
        #expect(state.partitionPageSizes == [10])
        #expect(state.partitionReadTimes == [readTime])
    }

    @Test("Snapshot listener options delegate server listeners")
    func testSnapshotListenerOptionsDelegateServerListeners() async throws {
        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let query = Query(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            predicates: [],
            runtime: runtime
        )
        let options = SnapshotListenOptions()
            .withIncludeMetadataChanges(true)
            .withSource(.default)

        _ = try await reference.addSnapshotListener(includeMetadataChanges: true)
        _ = try await query.addSnapshotListener(options: options)

        let state = runtime.snapshot()
        #expect(options.includeMetadataChanges == true)
        #expect(options.source == .default)
        #expect(state.listenDocumentPaths == ["users/user123"])
        #expect(state.listenQueryPaths == ["users"])
    }

    @Test("FirestoreAdmin delegates batch bulk and pipeline operations to runtime boundaries")
    func testFirestoreAdminDelegatesBatchBulkAndPipelineOperationsToRuntimeBoundaries() async throws {
        let runtime = RecordingRuntime()
        let firestore = Firestore(
            database: runtime.runtimeDatabase,
            referenceRuntime: runtime,
            collectionGroupRuntime: runtime,
            batchWriteRuntime: runtime,
            pipelineRuntime: runtime,
            transactionRuntime: runtime,
            makeBatchHandler: {
                FirestoreAdminWriteBatch(database: runtime.runtimeDatabase) { writes in
                    let didCommit = try await runtime.commitWrites(writes, transactionID: nil)
                    if !didCommit {
                        throw FirestoreError.commitFailed
                    }
                }
            },
            setLogLevelHandler: { _ in },
            shutdownHandler: {}
        )
        let batchDocument = try firestore.document("users/user123")
        let bulkDocument = try firestore.document("users/user456")
        let pipeline = firestore.pipeline().collection("users")

        try await firestore.batch()
            .setData(["name": "Ada"], forDocument: batchDocument)
            .commit()

        let bulkWriter = firestore.bulkWriter()
        bulkWriter.setData(["name": "Grace"], forDocument: bulkDocument)
        let bulkResult = try await bulkWriter.flush(labels: ["job": "backfill"])
        _ = try await firestore.execute(pipeline)
        _ = try await firestore.explain(pipeline, options: .analyzeJSON)

        let state = runtime.snapshot()
        #expect(state.setDataPaths.isEmpty)
        #expect(state.committedWritePaths == [["users/user123"]])
        #expect(state.commitTransactionIDs.count == 1)
        #expect(state.commitTransactionIDs[0] == nil)
        #expect(state.batchWritePaths == [["users/user456"]])
        #expect(state.batchWriteLabels == [["job": "backfill"]])
        #expect(bulkResult.results.map(\.document.path) == ["users/user456"])
        #expect(bulkResult.results.map(\.succeeded) == [true])
        #expect(state.executedPipelineStageNames == [["collection"]])
        #expect(state.explainedPipelineStageNames == [["collection"]])
        #expect(state.pipelineExplainOptions == [.analyzeJSON])
    }

    @Test("Collection and collection group direct query APIs forward through Query")
    func testCollectionAndCollectionGroupDirectQueryAPIsForwardThroughQuery() async throws {
        let runtime = RecordingRuntime()
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        let collectionGroup = CollectionGroup(
            runtime.runtimeDatabase,
            groupID: "posts",
            runtime: runtime
        )

        _ = try await collection.getDocuments()
        _ = try await collectionGroup.getDocuments()
        _ = try await collection.addSnapshotListener()
        _ = try await collectionGroup.addSnapshotListener(options: SnapshotListenOptions(includeMetadataChanges: true))
        _ = try await collectionGroup.aggregate([.count()])
        _ = try await collectionGroup.explain(options: .planOnly)

        var collectionIterator = collection.snapshots.makeAsyncIterator()
        var collectionGroupIterator = collectionGroup.snapshots.makeAsyncIterator()
        _ = try await collectionIterator.next()
        _ = try await collectionGroupIterator.next()

        let state = runtime.snapshot()
        #expect(state.queryPaths == ["users", "posts"])
        #expect(state.queryAllDescendants == [false, true])
        #expect(state.listenQueryPaths == ["users", "posts", "users", "posts"])
        #expect(state.listenQueryAllDescendants == [false, true, false, true])
        #expect(state.aggregateQueryPaths == ["posts"])
        #expect(state.aggregateQueryAllDescendants == [true])
        #expect(state.explainQueryPaths == ["posts"])
        #expect(state.explainQueryAllDescendants == [true])
    }

    @Test("Snapshot sequences lazily delegate server listeners")
    func testSnapshotSequencesLazilyDelegateServerListeners() async throws {
        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let query = Query(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            predicates: [],
            runtime: runtime
        )
        let options = SnapshotListenOptions(includeMetadataChanges: true)

        let documentSnapshots = reference.snapshots
        let querySnapshots = query.snapshots(options: options)

        var state = runtime.snapshot()
        #expect(state.listenDocumentPaths.isEmpty)
        #expect(state.listenQueryPaths.isEmpty)

        var documentIterator = documentSnapshots.makeAsyncIterator()
        var queryIterator = querySnapshots.makeAsyncIterator()
        _ = try await documentIterator.next()
        _ = try await queryIterator.next()

        state = runtime.snapshot()
        #expect(state.listenDocumentPaths == ["users/user123"])
        #expect(state.listenQueryPaths == ["users"])
    }

    @Test("Snapshot listener cache source throws server-side error")
    func testSnapshotListenerCacheSourceThrowsServerSideError() async throws {
        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let query = Query(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            predicates: [],
            runtime: runtime
        )
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        let collectionGroup = CollectionGroup(
            runtime.runtimeDatabase,
            groupID: "posts",
            runtime: runtime
        )
        let options = SnapshotListenOptions(source: .cache)

        var documentDidThrow = false
        do {
            _ = try await reference.addSnapshotListener(options: options)
        } catch FirestoreError.invalidOperation(let message) {
            documentDidThrow = message.contains("Cache-only")
        } catch {
            documentDidThrow = false
        }

        var queryDidThrow = false
        do {
            _ = try await query.addSnapshotListener(options: options)
        } catch FirestoreError.invalidOperation(let message) {
            queryDidThrow = message.contains("Cache-only")
        } catch {
            queryDidThrow = false
        }

        var collectionDidThrow = false
        do {
            _ = try await collection.addSnapshotListener(options: options)
        } catch FirestoreError.invalidOperation(let message) {
            collectionDidThrow = message.contains("Cache-only")
        } catch {
            collectionDidThrow = false
        }

        var collectionGroupDidThrow = false
        do {
            _ = try await collectionGroup.addSnapshotListener(options: options)
        } catch FirestoreError.invalidOperation(let message) {
            collectionGroupDidThrow = message.contains("Cache-only")
        } catch {
            collectionGroupDidThrow = false
        }

        let state = runtime.snapshot()
        #expect(documentDidThrow)
        #expect(queryDidThrow)
        #expect(collectionDidThrow)
        #expect(collectionGroupDidThrow)
        #expect(state.listenDocumentPaths.isEmpty)
        #expect(state.listenQueryPaths.isEmpty)
    }

    @Test("Snapshot sequence cache source throws server-side error")
    func testSnapshotSequenceCacheSourceThrowsServerSideError() async throws {
        let runtime = RecordingRuntime()
        let reference = DocumentReference(
            runtime.runtimeDatabase,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let query = Query(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            predicates: [],
            runtime: runtime
        )
        let collection = CollectionReference(
            runtime.runtimeDatabase,
            parentPath: nil,
            collectionID: "users",
            runtime: runtime
        )
        let collectionGroup = CollectionGroup(
            runtime.runtimeDatabase,
            groupID: "posts",
            runtime: runtime
        )
        let options = SnapshotListenOptions(source: .cache)

        var documentDidThrow = false
        var documentIterator = reference.snapshots(options: options).makeAsyncIterator()
        do {
            _ = try await documentIterator.next()
        } catch FirestoreError.invalidOperation(let message) {
            documentDidThrow = message.contains("Cache-only")
        } catch {
            documentDidThrow = false
        }

        var queryDidThrow = false
        var queryIterator = query.snapshots(options: options).makeAsyncIterator()
        do {
            _ = try await queryIterator.next()
        } catch FirestoreError.invalidOperation(let message) {
            queryDidThrow = message.contains("Cache-only")
        } catch {
            queryDidThrow = false
        }

        var collectionDidThrow = false
        var collectionIterator = collection.snapshots(options: options).makeAsyncIterator()
        do {
            _ = try await collectionIterator.next()
        } catch FirestoreError.invalidOperation(let message) {
            collectionDidThrow = message.contains("Cache-only")
        } catch {
            collectionDidThrow = false
        }

        var collectionGroupDidThrow = false
        var collectionGroupIterator = collectionGroup.snapshots(options: options).makeAsyncIterator()
        do {
            _ = try await collectionGroupIterator.next()
        } catch FirestoreError.invalidOperation(let message) {
            collectionGroupDidThrow = message.contains("Cache-only")
        } catch {
            collectionGroupDidThrow = false
        }

        let state = runtime.snapshot()
        #expect(documentDidThrow)
        #expect(queryDidThrow)
        #expect(collectionDidThrow)
        #expect(collectionGroupDidThrow)
        #expect(state.listenDocumentPaths.isEmpty)
        #expect(state.listenQueryPaths.isEmpty)
    }

    @Test("Unbound reference throws typed error")
    func testUnboundReferenceThrowsTypedError() async {
        let reference = DocumentReference(
            Database(projectId: "test"),
            parentPath: "users",
            documentID: "user123"
        )

        var didThrowUnboundReference = false
        do {
            _ = try await reference.getDocument()
        } catch FirestoreError.unboundReference(_) {
            didThrowUnboundReference = true
        } catch {
            didThrowUnboundReference = false
        }

        #expect(didThrowUnboundReference)
    }

    @Test("Runtime-backed API throws typed access token error")
    func testRuntimeBackedAPIThrowsTypedAccessTokenError() async throws {
        let firestore = Firestore(projectId: "test", transport: MockClientTransport())
        let reference = try firestore.document("users/user123")

        var didThrowInvalidAccessToken = false
        do {
            _ = try await reference.getDocument()
        } catch FirestoreError.invalidAccessToken(_) {
            didThrowInvalidAccessToken = true
        } catch {
            didThrowInvalidAccessToken = false
        }

        #expect(didThrowInvalidAccessToken)
    }
}

private final class RecordingRuntime: FirestoreRuntime, FirestoreTransactionRuntime {
    struct State: Sendable {
        var getDocumentPaths: [String] = []
        var setDataPaths: [String] = []
        var setDataMergeFlags: [Bool] = []
        var setDataMergeFields: [[String]] = []
        var updateDataPaths: [String] = []
        var deleteDocumentPaths: [String] = []
        var listCollectionPaths: [String] = []
        var queryPaths: [String] = []
        var queryAllDescendants: [Bool] = []
        var aggregateQueryPaths: [String] = []
        var aggregateQueryAllDescendants: [Bool] = []
        var explainQueryPaths: [String] = []
        var explainQueryAllDescendants: [Bool] = []
        var explainOptions: [FirestoreExplainOptions] = []
        var explainAggregationQueryPaths: [String] = []
        var explainAggregationOptions: [FirestoreExplainOptions] = []
        var listDocumentCollectionPaths: [String] = []
        var listDocumentPageSizes: [Int] = []
        var listDocumentReadTimes: [Timestamp?] = []
        var partitionCollectionGroupIDs: [String] = []
        var partitionPointCounts: [Int] = []
        var partitionPageSizes: [Int] = []
        var partitionReadTimes: [Timestamp?] = []
        var listenDocumentPaths: [String] = []
        var listenQueryPaths: [String] = []
        var listenQueryAllDescendants: [Bool] = []
        var committedWritePaths: [[String]] = []
        var commitTransactionIDs: [Data?] = []
        var batchWritePaths: [[String]] = []
        var batchWriteLabels: [[String: String]] = []
        var executedPipelineStageNames: [[String]] = []
        var explainedPipelineStageNames: [[String]] = []
        var pipelineExplainOptions: [PipelineExplainOptions] = []
        var documentFields: [String: FirestoreDocumentValue]?
        var querySnapshot = QuerySnapshot(documents: [])
    }

    let runtimeDatabase = Database(projectId: "test")
    private let state = Mutex(State())

    func snapshot() -> State {
        state.withLock { $0 }
    }

    func setReadResults(documentFields: [String: FirestoreDocumentValue]?, querySnapshot: QuerySnapshot) {
        state.withLock {
            $0.documentFields = documentFields
            $0.querySnapshot = querySnapshot
        }
    }

    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        let fields = state.withLock { state in
            state.getDocumentPaths.append(reference.path)
            return state.documentFields
        }
        return DocumentSnapshot(fields: fields, documentReference: reference)
    }

    func setData(_ data: [String: Any], merge: Bool, for reference: DocumentReference) async throws {
        state.withLock {
            $0.setDataPaths.append(reference.path)
            $0.setDataMergeFlags.append(merge)
        }
    }

    func setData(_ data: [String: Any], mergeFields: [String], for reference: DocumentReference) async throws {
        state.withLock {
            $0.setDataPaths.append(reference.path)
            $0.setDataMergeFields.append(mergeFields)
        }
    }

    func updateData(_ fields: [String: Any], for reference: DocumentReference) async throws {
        state.withLock { $0.updateDataPaths.append(reference.path) }
    }

    func deleteDocument(_ reference: DocumentReference) async throws {
        state.withLock { $0.deleteDocumentPaths.append(reference.path) }
    }

    func listCollections(in reference: DocumentReference) async throws -> [CollectionReference] {
        state.withLock { $0.listCollectionPaths.append(reference.path) }
        return [
            CollectionReference(
                runtimeDatabase,
                parentPath: reference.path,
                collectionID: "posts",
                runtime: self
            )
        ]
    }

    func listDocuments(
        in collection: CollectionReference,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [DocumentReference] {
        state.withLock {
            $0.listDocumentCollectionPaths.append(collection.path)
            $0.listDocumentPageSizes.append(pageSize)
            $0.listDocumentReadTimes.append(readTime)
        }
        return [
            DocumentReference(
                runtimeDatabase,
                parentPath: collection.path,
                documentID: "user123",
                runtime: self
            ),
            DocumentReference(
                runtimeDatabase,
                parentPath: collection.path,
                documentID: "user456",
                runtime: self
            )
        ]
    }

    func listen(to reference: DocumentReference) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        state.withLock { $0.listenDocumentPaths.append(reference.path) }
        return AsyncThrowingStream<DocumentSnapshot, Error> { continuation in
            continuation.finish()
        }
    }

    func getDocuments(for query: Query) async throws -> QuerySnapshot {
        state.withLock {
            $0.queryPaths.append(query.path)
            $0.queryAllDescendants.append(query.allDescendants)
            return $0.querySnapshot
        }
    }

    func listen(to query: Query) async throws -> AsyncThrowingStream<QuerySnapshot, Error> {
        state.withLock {
            $0.listenQueryPaths.append(query.path)
            $0.listenQueryAllDescendants.append(query.allDescendants)
        }
        return AsyncThrowingStream<QuerySnapshot, Error> { continuation in
            continuation.finish()
        }
    }

    func aggregate(_ query: Query, fields: [AggregateField]) async throws -> AggregateQuerySnapshot {
        state.withLock {
            $0.aggregateQueryPaths.append(query.path)
            $0.aggregateQueryAllDescendants.append(query.allDescendants)
        }
        let data = Dictionary(
            uniqueKeysWithValues: fields.map { field in
                switch field.operation {
                case .count:
                    return (field.alias, AggregateValue.integer(0))
                case .sum, .average:
                    return (field.alias, AggregateValue.null)
                }
            }
        )
        return AggregateQuerySnapshot(data: data)
    }

    func partitionedQueries(
        for collectionGroup: CollectionGroup,
        partitionPointCount: Int,
        pageSize: Int,
        readTime: Timestamp?
    ) async throws -> [Query] {
        state.withLock {
            $0.partitionCollectionGroupIDs.append(collectionGroup.groupID)
            $0.partitionPointCounts.append(partitionPointCount)
            $0.partitionPageSizes.append(pageSize)
            $0.partitionReadTimes.append(readTime)
        }
        return [collectionGroup.limit(to: partitionPointCount)]
    }

    func explain(_ query: Query, options: FirestoreExplainOptions) async throws -> QueryExplainResult {
        state.withLock {
            $0.explainQueryPaths.append(query.path)
            $0.explainQueryAllDescendants.append(query.allDescendants)
            $0.explainOptions.append(options)
        }
        return QueryExplainResult(
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
        state.withLock {
            $0.explainAggregationQueryPaths.append(query.path)
            $0.explainAggregationOptions.append(options)
        }
        return AggregateQueryExplainResult(
            snapshot: nil,
            metrics: FirestoreExplainMetrics(
                planSummary: FirestoreExplainPlanSummary(indexesUsed: []),
                executionStats: nil
            )
        )
    }

    func batchWrite(_ writes: [WriteData], labels: [String: String]) async throws -> FirestoreBulkWriteResult {
        state.withLock {
            $0.batchWritePaths.append(writes.map(\.documentReference.path))
            $0.batchWriteLabels.append(labels)
        }
        return FirestoreBulkWriteResult(
            results: writes.enumerated().map { offset, write in
                FirestoreBulkWriteOperationResult(
                    index: offset,
                    document: write.documentReference,
                    updateTime: nil,
                    error: nil
                )
            }
        )
    }

    func executePipeline(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
        state.withLock { $0.executedPipelineStageNames.append(pipeline.stages.map(\.name)) }
        return PipelineQuerySnapshot(rows: [], executionTime: nil)
    }

    func explainPipeline(_ pipeline: FirestorePipeline, options: PipelineExplainOptions) async throws -> PipelineExplainResult {
        state.withLock {
            $0.explainedPipelineStageNames.append(pipeline.stages.map(\.name))
            $0.pipelineExplainOptions.append(options)
        }
        return PipelineExplainResult(
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

    func beginTransactionID(readOnly: Bool, readTime: Timestamp?, retryTransactionID: Data?) async throws -> Data {
        Data([1])
    }

    func batchGetDocuments(documentReferences: [DocumentReference], transactionID: Data?) async throws -> [DocumentSnapshot] {
        documentReferences.map { DocumentSnapshot(documentReference: $0) }
    }

    func runQuery(query: Query, transactionID: Data?) async throws -> QuerySnapshot {
        try await getDocuments(for: query)
    }

    func commitWrites(_ writes: [WriteData], transactionID: Data?) async throws -> Bool {
        state.withLock {
            $0.committedWritePaths.append(writes.map(\.documentReference.path))
            $0.commitTransactionIDs.append(transactionID)
        }
        return true
    }

    func rollbackTransactionID(transactionID: Data) async throws {}
}
