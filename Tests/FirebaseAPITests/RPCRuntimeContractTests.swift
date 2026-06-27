import Foundation
import FirestoreGRPCTransport
import FirestoreProtobuf
import FirestoreRPC
import FirestoreAuthCore
import FirestoreRuntimeConfig
import GRPCCore
import SwiftProtobuf
import Testing
@testable import FirestoreAPI

@Suite("RPC Runtime Contract Tests")
struct RPCRuntimeContractTests {
    @Test("DocumentReference getDocument sends GetDocument with configured timeout")
    func testGetDocumentUsesConfiguredTimeout() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_Document.with {
                    $0.name = "projects/test-project/databases/(default)/documents/users/user123"
                    $0.fields["name"] = Google_Firestore_V1_Value.with {
                        $0.stringValue = "Ada"
                    }
                }
            ),
            forMethod: "GetDocument"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(7), retryStrategy: .none, logLevel: .warning)
        )
        let document = try firestore.document("users/user123")

        let snapshot = try await document.getDocument()
        await firestore.shutdown()

        let calls = await state.snapshot()
        let getCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_GetDocumentRequest.self,
            from: getCall
        )

        #expect(snapshot.exists)
        #expect(snapshot.data()?["name"] as? String == "Ada")
        #expect(calls.map(\.descriptor.method) == ["GetDocument"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/GetDocument"])
        #expect(getCall.options.timeout == .seconds(7))
        #expect(request.name == "projects/test-project/databases/(default)/documents/users/user123")
    }

    @Test("Finite RPC retry refreshes authorization metadata per attempt")
    func testFiniteRPCRetryRefreshesAuthorizationMetadataPerAttempt() async throws {
        let state = RecordingTransportState()
        await state.enqueueResponseParts(
            [
                .metadata([:]),
                .status(Status(code: .unavailable, message: "retry"), [:])
            ],
            forMethod: "GetDocument"
        )
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_Document.with {
                    $0.name = "projects/test-project/databases/(default)/documents/users/user123"
                    $0.fields["name"] = Google_Firestore_V1_Value.with {
                        $0.stringValue = "Ada"
                    }
                }
            ),
            forMethod: "GetDocument"
        )

        let tokenProvider = IncrementingAccessTokenProvider()
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: FirestoreSettings(
                timeout: .seconds(7),
                maxRetryAttempts: 2,
                retryStrategy: .custom { _ in .milliseconds(1) },
                logLevel: .warning
            ),
            accessTokenProvider: tokenProvider
        )
        let document = try firestore.document("users/user123")

        let snapshot = try await document.getDocument()
        await firestore.shutdown()

        let calls = await state.snapshot()
        #expect(snapshot.exists)
        #expect(calls.map(\.descriptor.method) == ["GetDocument", "GetDocument"])
        #expect(Self.requestAuthorization(from: calls[0]) == "Bearer token-1")
        #expect(Self.requestAuthorization(from: calls[1]) == "Bearer token-2")
        #expect(await tokenProvider.tokenCount == 2)
    }

    @Test("Query getDocuments sends RunQuery with configured timeout")
    func testQueryGetDocumentsSendsRunQueryWithConfiguredTimeout() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts([
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.document = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/users/user123"
                        $0.fields["score"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 42
                        }
                    }
                }
            ]),
            forMethod: "RunQuery"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(12), retryStrategy: .none, logLevel: .warning)
        )
        let query = try firestore.collection("users")
            .whereField("active", isEqualTo: true)
            .order(by: "score", descending: false)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()
        await firestore.shutdown()

        let calls = await state.snapshot()
        let runQueryCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_RunQueryRequest.self,
            from: runQueryCall
        )
        let structuredQuery = request.structuredQuery

        #expect(snapshot.documents.map(\.id) == ["user123"])
        let firstDocumentData = try #require(snapshot.documents.first?.data())
        #expect(firstDocumentData["score"] as? Int == 42)
        #expect(calls.map(\.descriptor.method) == ["RunQuery"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/RunQuery"])
        #expect(runQueryCall.options.timeout == .seconds(12))
        #expect(request.parent == "projects/test-project/databases/(default)/documents")
        #expect(structuredQuery.from.first?.collectionID == "users")
        #expect(structuredQuery.where.fieldFilter.field.fieldPath == "active")
        #expect(structuredQuery.where.fieldFilter.value.booleanValue)
        #expect(structuredQuery.orderBy.first?.field.fieldPath == "score")
        #expect(structuredQuery.limit.value == 1)
    }

    @Test("Query findNearest sends RunQuery vector config")
    func testQueryFindNearestSendsRunQueryVectorConfig() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts([
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.document = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/cities/SF"
                        $0.fields["name"] = Google_Firestore_V1_Value.with {
                            $0.stringValue = "San Francisco"
                        }
                    }
                }
            ]),
            forMethod: "RunQuery"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(12), retryStrategy: .none, logLevel: .warning)
        )
        let query = try firestore.collection("cities")
            .whereField("country", isEqualTo: "USA")
            .findNearest(
                vectorField: "embedding",
                queryVector: FirestoreVector([1.0, 2.0, 3.0]),
                limit: 4,
                distanceMeasure: .cosine,
                distanceResultField: "distance"
            )

        let snapshot = try await query.getDocuments()
        await firestore.shutdown()

        let calls = await state.snapshot()
        let runQueryCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_RunQueryRequest.self,
            from: runQueryCall
        )
        let findNearest = request.structuredQuery.findNearest

        #expect(snapshot.documents.map(\.id) == ["SF"])
        #expect(calls.map(\.descriptor.method) == ["RunQuery"])
        #expect(runQueryCall.options.timeout == .seconds(12))
        #expect(request.structuredQuery.where.fieldFilter.field.fieldPath == "country")
        #expect(request.structuredQuery.hasFindNearest)
        #expect(findNearest.vectorField.fieldPath == "embedding")
        #expect(findNearest.queryVector.arrayValue.values.map(\.doubleValue) == [1.0, 2.0, 3.0])
        #expect(findNearest.distanceMeasure == .cosine)
        #expect(findNearest.limit.value == 4)
        #expect(findNearest.distanceResultField == "distance")
    }

    @Test("Query explain sends RunQuery explain options")
    func testQueryExplainSendsRunQueryExplainOptions() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts([
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.document = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/users/user123"
                    }
                },
                Google_Firestore_V1_RunQueryResponse.with {
                    $0.explainMetrics = Self.makeExplainMetrics()
                }
            ]),
            forMethod: "RunQuery"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(13), retryStrategy: .none, logLevel: .warning)
        )
        let query = try firestore.collection("users").whereField("active", isEqualTo: true)

        let result = try await query.explain(options: .analyze)
        await firestore.shutdown()

        let calls = await state.snapshot()
        let runQueryCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_RunQueryRequest.self,
            from: runQueryCall
        )

        #expect(result.snapshot?.documents.map(\.id) == ["user123"])
        #expect(result.metrics.executionStats?.readOperations == 1)
        #expect(calls.map(\.descriptor.method) == ["RunQuery"])
        #expect(runQueryCall.options.timeout == .seconds(13))
        #expect(request.hasExplainOptions)
        #expect(request.explainOptions.analyze)
        #expect(request.structuredQuery.from.first?.collectionID == "users")
    }

    @Test("CollectionGroup partitionedQueries sends paged PartitionQuery requests")
    func testCollectionGroupPartitionedQueriesSendsPagedPartitionQueryRequests() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_PartitionQueryResponse.with {
                    $0.partitions = [
                        Self.partitionCursor("projects/test-project/databases/(default)/documents/users/a/posts/post1")
                    ]
                    $0.nextPageToken = "next-page"
                }
            ),
            forMethod: "PartitionQuery"
        )
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_PartitionQueryResponse.with {
                    $0.partitions = [
                        Self.partitionCursor("projects/test-project/databases/(default)/documents/users/m/posts/post9")
                    ]
                }
            ),
            forMethod: "PartitionQuery"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(9), retryStrategy: .none, logLevel: .warning)
        )
        let collectionGroup = try firestore.collectionGroup("posts")

        let partitions = try await collectionGroup.partitionedQueries(
            partitionPointCount: 2,
            pageSize: 1,
            readTime: Timestamp(seconds: 123, nanos: 456)
        )
        await firestore.shutdown()

        let calls = await state.snapshot()
        let requests = try calls.map { call in
            try Self.decodeSingleMessage(
                Google_Firestore_V1_PartitionQueryRequest.self,
                from: call
            )
        }
        let firstRequest = try #require(requests.first)
        let secondRequest = try #require(requests.dropFirst().first)
        #expect(partitions.count == 3)
        let firstPartition = try #require(partitions.first)
        let middlePartition = try #require(partitions.dropFirst().first)
        let lastPartition = try #require(partitions.dropFirst(2).first)
        let firstQuery = try QueryCompiler(query: firstPartition).makeStructuredQuery()
        let middleQuery = try QueryCompiler(query: middlePartition).makeStructuredQuery()
        let lastQuery = try QueryCompiler(query: lastPartition).makeStructuredQuery()

        #expect(calls.map(\.descriptor.method) == ["PartitionQuery", "PartitionQuery"])
        #expect(calls.allSatisfy { $0.options.timeout == .seconds(9) })
        #expect(firstRequest.parent == "projects/test-project/databases/(default)/documents")
        #expect(firstRequest.partitionCount == 2)
        #expect(firstRequest.pageSize == 1)
        #expect(firstRequest.pageToken.isEmpty)
        #expect(firstRequest.readTime.seconds == 123)
        #expect(firstRequest.readTime.nanos == 456)
        #expect(firstRequest.structuredQuery.from.first?.collectionID == "posts")
        #expect(firstRequest.structuredQuery.from.first?.allDescendants == true)
        #expect(firstRequest.structuredQuery.orderBy.map(\.field.fieldPath) == ["__name__"])
        #expect(secondRequest.pageToken == "next-page")
        #expect(firstQuery.endAt.values.first?.referenceValue == "projects/test-project/databases/(default)/documents/users/a/posts/post1")
        #expect(firstQuery.endAt.before)
        #expect(middleQuery.startAt.values.first?.referenceValue == "projects/test-project/databases/(default)/documents/users/a/posts/post1")
        #expect(middleQuery.startAt.before)
        #expect(middleQuery.endAt.values.first?.referenceValue == "projects/test-project/databases/(default)/documents/users/m/posts/post9")
        #expect(middleQuery.endAt.before)
        #expect(lastQuery.startAt.values.first?.referenceValue == "projects/test-project/databases/(default)/documents/users/m/posts/post9")
        #expect(lastQuery.startAt.before)
    }

    @Test("BeginTransaction sends read-write retry and read-only read-time options")
    func testBeginTransactionRequestOptions() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_BeginTransactionResponse.with {
                    $0.transaction = Data([1, 2, 3])
                }
            ),
            forMethod: "BeginTransaction"
        )
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_BeginTransactionResponse.with {
                    $0.transaction = Data([4, 5, 6])
                }
            ),
            forMethod: "BeginTransaction"
        )
        let runtime = FirestoreGRPCRuntime(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(14), retryStrategy: .none, logLevel: .warning)
        )

        let readWriteResponse = try await runtime.beginTransaction(
            readOnly: false,
            readTime: nil,
            retryTransactionID: Data([9, 8])
        )
        let readOnlyResponse = try await runtime.beginTransaction(
            readOnly: true,
            readTime: Timestamp(seconds: 123, nanos: 456),
            retryTransactionID: Data([7, 6])
        )
        await runtime.shutdown()

        let calls = await state.snapshot()
        let requests = try calls.map { call in
            try Self.decodeSingleMessage(
                Google_Firestore_V1_BeginTransactionRequest.self,
                from: call
            )
        }
        let readWriteRequest = try #require(requests.first)
        let readOnlyRequest = try #require(requests.dropFirst().first)

        #expect(readWriteResponse.transaction == Data([1, 2, 3]))
        #expect(readOnlyResponse.transaction == Data([4, 5, 6]))
        #expect(calls.map(\.descriptor.method) == ["BeginTransaction", "BeginTransaction"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == [
            "google.firestore.v1.Firestore/BeginTransaction",
            "google.firestore.v1.Firestore/BeginTransaction"
        ])
        #expect(calls.allSatisfy { $0.options.timeout == .seconds(14) })
        #expect(readWriteRequest.database == "projects/test-project/databases/(default)")
        #expect(readWriteRequest.options.readWrite.retryTransaction == Data([9, 8]))
        #expect(readWriteRequest.options.readWrite.concurrencyMode == .optimistic)
        #expect(readOnlyRequest.database == "projects/test-project/databases/(default)")
        #expect(readOnlyRequest.options.readOnly.readTime.seconds == 123)
        #expect(readOnlyRequest.options.readOnly.readTime.nanos == 456)
        #expect(readOnlyRequest.options.readWrite.retryTransaction.isEmpty)
    }

    @Test("Transactional document reads send BatchGetDocuments with transaction ID")
    func testBatchGetDocumentsUsesTransactionID() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts([
                Google_Firestore_V1_BatchGetDocumentsResponse.with {
                    $0.found = Google_Firestore_V1_Document.with {
                        $0.name = "projects/test-project/databases/(default)/documents/users/user123"
                        $0.fields["name"] = Google_Firestore_V1_Value.with {
                            $0.stringValue = "Ada"
                        }
                    }
                },
                Google_Firestore_V1_BatchGetDocumentsResponse.with {
                    $0.missing = "projects/test-project/databases/(default)/documents/users/missing"
                }
            ]),
            forMethod: "BatchGetDocuments"
        )
        let runtime = FirestoreGRPCRuntime(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(15), retryStrategy: .none, logLevel: .warning)
        )
        let existingDocument = DocumentReference(
            runtime.database,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )
        let missingDocument = DocumentReference(
            runtime.database,
            parentPath: "users",
            documentID: "missing",
            runtime: runtime
        )

        let snapshots = try await runtime.batchGetDocuments(
            documentReferences: [existingDocument, missingDocument],
            transactionID: Data([5, 6])
        )
        await runtime.shutdown()

        let calls = await state.snapshot()
        let batchGetCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_BatchGetDocumentsRequest.self,
            from: batchGetCall
        )

        #expect(snapshots.count == 2)
        #expect(snapshots[0].exists)
        #expect(snapshots[0].data()?["name"] as? String == "Ada")
        #expect(!snapshots[1].exists)
        #expect(calls.map(\.descriptor.method) == ["BatchGetDocuments"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/BatchGetDocuments"])
        #expect(batchGetCall.options.timeout == .seconds(15))
        #expect(request.database == "projects/test-project/databases/(default)")
        #expect(request.documents == [
            "projects/test-project/databases/(default)/documents/users/user123",
            "projects/test-project/databases/(default)/documents/users/missing"
        ])
        #expect(request.transaction == Data([5, 6]))
    }

    @Test("Transactional commit and rollback send transaction IDs")
    func testTransactionalCommitAndRollbackUseTransactionID() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_CommitResponse.with {
                    $0.commitTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 10
                    }
                }
            ),
            forMethod: "Commit"
        )
        try await state.enqueueResponseParts(
            Self.responseParts(Google_Protobuf_Empty()),
            forMethod: "Rollback"
        )
        let runtime = FirestoreGRPCRuntime(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(16), retryStrategy: .none, logLevel: .warning)
        )
        let document = DocumentReference(
            runtime.database,
            parentPath: "users",
            documentID: "user123",
            runtime: runtime
        )

        let didCommit = try await runtime.commitWrites(
            [
                WriteData(
                    documentReference: document,
                    data: ["name": "Ada"],
                    merge: false,
                    mergeFields: nil,
                    exist: nil
                )
            ],
            transactionID: Data([7, 8])
        )
        try await runtime.rollbackTransactionID(transactionID: Data([7, 8]))
        await runtime.shutdown()

        let calls = await state.snapshot()
        let commitCall = try #require(calls.first)
        let rollbackCall = try #require(calls.dropFirst().first)
        let commitRequest = try Self.decodeSingleMessage(
            Google_Firestore_V1_CommitRequest.self,
            from: commitCall
        )
        let rollbackRequest = try Self.decodeSingleMessage(
            Google_Firestore_V1_RollbackRequest.self,
            from: rollbackCall
        )

        #expect(didCommit)
        #expect(calls.map(\.descriptor.method) == ["Commit", "Rollback"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == [
            "google.firestore.v1.Firestore/Commit",
            "google.firestore.v1.Firestore/Rollback"
        ])
        #expect(calls.allSatisfy { $0.options.timeout == .seconds(16) })
        #expect(commitRequest.database == "projects/test-project/databases/(default)")
        #expect(commitRequest.transaction == Data([7, 8]))
        #expect(commitRequest.writes.first?.update.name == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(rollbackRequest.database == "projects/test-project/databases/(default)")
        #expect(rollbackRequest.transaction == Data([7, 8]))
    }

    @Test("BulkWriter flush sends BatchWrite and maps per-write status")
    func testBulkWriterFlushSendsBatchWriteAndMapsPerWriteStatus() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_BatchWriteResponse.with {
                    $0.writeResults = [
                        Google_Firestore_V1_WriteResult.with {
                            $0.updateTime = Google_Protobuf_Timestamp.with {
                                $0.seconds = 42
                                $0.nanos = 7
                            }
                        },
                        Google_Firestore_V1_WriteResult()
                    ]
                    $0.status = [
                        Google_Rpc_Status(),
                        Google_Rpc_Status.with {
                            $0.code = Int32(FirestoreErrorCode.notFound.rawValue)
                            $0.message = "missing"
                        }
                    ]
                }
            ),
            forMethod: "BatchWrite"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(19), retryStrategy: .none, logLevel: .warning)
        )
        let firstDocument = try firestore.document("users/user123")
        let secondDocument = try firestore.document("users/user456")
        let writer = firestore.bulkWriter()
        writer
            .setData(["name": "Ada"], forDocument: firstDocument)
            .deleteDocument(secondDocument)

        let result = try await writer.flush(labels: ["job": "backfill"])
        await firestore.shutdown()

        let calls = await state.snapshot()
        let batchWriteCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_BatchWriteRequest.self,
            from: batchWriteCall
        )

        #expect(result.results.count == 2)
        #expect(result.succeeded.map(\.document) == [firstDocument])
        #expect(result.failed.map(\.document) == [secondDocument])
        #expect(result.results[0].updateTime == Timestamp(seconds: 42, nanos: 7))
        #expect(result.results[1].error?.code == .notFound)
        #expect(calls.map(\.descriptor.method) == ["BatchWrite"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/BatchWrite"])
        #expect(batchWriteCall.options.timeout == .seconds(19))
        #expect(request.database == "projects/test-project/databases/(default)")
        #expect(request.labels == ["job": "backfill"])
        #expect(request.writes.count == 2)
        #expect(request.writes[0].update.name == "projects/test-project/databases/(default)/documents/users/user123")
        #expect(request.writes[0].update.fields["name"]?.stringValue == "Ada")
        #expect(request.writes[1].delete == "projects/test-project/databases/(default)/documents/users/user456")
    }

    @Test("Collection count sends RunAggregationQuery with configured timeout")
    func testCountSendsRunAggregationQueryWithConfiguredTimeout() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.result = Google_Firestore_V1_AggregationResult.with {
                        $0.aggregateFields["count"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 3
                        }
                    }
                }
            ),
            forMethod: "RunAggregationQuery"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(17), retryStrategy: .none, logLevel: .warning)
        )
        let collection = try firestore.collection("users")

        let count = try await collection.count()
        await firestore.shutdown()

        let calls = await state.snapshot()
        let aggregationCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_RunAggregationQueryRequest.self,
            from: aggregationCall
        )
        let aggregationQuery = request.structuredAggregationQuery
        let aggregation = try #require(aggregationQuery.aggregations.first)

        #expect(count == 3)
        #expect(calls.map(\.descriptor.method) == ["RunAggregationQuery"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/RunAggregationQuery"])
        #expect(aggregationCall.options.timeout == .seconds(17))
        #expect(request.parent == "projects/test-project/databases/(default)/documents")
        #expect(aggregationQuery.structuredQuery.from.first?.collectionID == "users")
        #expect(aggregation.alias == "count")
        if case .count = aggregation.operator {
            #expect(true)
        } else {
            Issue.record("Count should compile to a count aggregation operator.")
        }
    }

    @Test("Query aggregate sends count sum and average")
    func testQueryAggregateSendsCountSumAndAverage() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.result = Google_Firestore_V1_AggregationResult.with {
                        $0.aggregateFields["count"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 4
                        }
                        $0.aggregateFields["sum_population"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 12_300
                        }
                        $0.aggregateFields["average_population"] = Google_Firestore_V1_Value.with {
                            $0.doubleValue = 3_075
                        }
                    }
                }
            ),
            forMethod: "RunAggregationQuery"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(18), retryStrategy: .none, logLevel: .warning)
        )
        let query = try firestore.collection("cities").whereField("capital", isEqualTo: true)
        let count = AggregateField.count()
        let sum = AggregateField.sum("population")
        let average = AggregateField.average("population")

        let snapshot = try await query.aggregate([count, sum, average])
        await firestore.shutdown()

        let calls = await state.snapshot()
        let aggregationCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_RunAggregationQueryRequest.self,
            from: aggregationCall
        )
        let aggregations = request.structuredAggregationQuery.aggregations

        #expect(snapshot.get(count)?.intValue == 4)
        #expect(snapshot.get(sum)?.int64Value == 12_300)
        #expect(snapshot.get(average)?.doubleValue == 3_075)
        #expect(calls.map(\.descriptor.method) == ["RunAggregationQuery"])
        #expect(aggregationCall.options.timeout == .seconds(18))
        #expect(aggregations.map { $0.alias } == ["count", "sum_population", "average_population"])
        #expect(aggregations[1].sum.field.fieldPath == "population")
        #expect(aggregations[2].avg.field.fieldPath == "population")
    }

    @Test("Query explain aggregation sends RunAggregationQuery explain options")
    func testQueryExplainAggregationSendsRunAggregationQueryExplainOptions() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts([
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.result = Google_Firestore_V1_AggregationResult.with {
                        $0.aggregateFields["count"] = Google_Firestore_V1_Value.with {
                            $0.integerValue = 8
                        }
                    }
                },
                Google_Firestore_V1_RunAggregationQueryResponse.with {
                    $0.explainMetrics = Self.makeExplainMetrics()
                }
            ]),
            forMethod: "RunAggregationQuery"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(19), retryStrategy: .none, logLevel: .warning)
        )
        let query = try firestore.collection("cities").whereField("capital", isEqualTo: true)
        let count = AggregateField.count()

        let result = try await query.explainAggregation([count], options: .planOnly)
        await firestore.shutdown()

        let calls = await state.snapshot()
        let aggregationCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_RunAggregationQueryRequest.self,
            from: aggregationCall
        )

        #expect(result.snapshot?.get(count)?.int64Value == 8)
        #expect(result.metrics.planSummary.indexesUsed.first?["query_scope"] == .string("Collection"))
        #expect(calls.map(\.descriptor.method) == ["RunAggregationQuery"])
        #expect(aggregationCall.options.timeout == .seconds(19))
        #expect(request.hasExplainOptions)
        #expect(!request.explainOptions.analyze)
        #expect(request.structuredAggregationQuery.aggregations.first?.alias == "count")
    }

    @Test("FirestoreAdmin execute sends pipeline subquery")
    func testExecutePipelineSendsSubquery() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ExecutePipelineResponse.with {
                    $0.results = [
                        Google_Firestore_V1_Document.with {
                            $0.name = "projects/test-project/databases/(default)/documents/reviewers/alice"
                            $0.fields["name"] = Google_Firestore_V1_Value.with {
                                $0.stringValue = "Alice"
                            }
                            $0.createTime = Google_Protobuf_Timestamp.with {
                                $0.seconds = 10
                                $0.nanos = 20
                            }
                            $0.updateTime = Google_Protobuf_Timestamp.with {
                                $0.seconds = 30
                                $0.nanos = 40
                            }
                        }
                    ]
                    $0.executionTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 100
                        $0.nanos = 2
                    }
                }
            ),
            forMethod: "ExecutePipeline"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(19), retryStrategy: .none, logLevel: .warning)
        )
        let subquery = firestore.pipeline()
            .collectionGroup("reviews")
            .where(.field("author").equal(.variable("reviewer_name")))
            .where(.field("rating").lessThan(2))
        let pipeline = firestore.pipeline()
            .collection("reviewers")
            .define([.field("__name__").as("reviewer_name")])
            .select([.field("__name__"), subquery.toArrayExpression().as("negative_reviews")])

        let snapshot = try await firestore.execute(pipeline)
        await firestore.shutdown()

        let calls = await state.snapshot()
        let pipelineCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_ExecutePipelineRequest.self,
            from: pipelineCall
        )
        let stages = request.structuredPipeline.pipeline.stages
        let arrayExpression = stages[2].args[1].functionValue.args[0].functionValue
        let subqueryStages = arrayExpression.args[0].pipelineValue.stages
        let row = try #require(snapshot.resultRows.first)
        let documentReference = try #require(row.documentReference)

        #expect(snapshot.rows.first?["name"] as? String == "Alice")
        #expect(row.data["name"] as? String == "Alice")
        #expect(documentReference.path == "reviewers/alice")
        #expect(row.createTime == Timestamp(seconds: 10, nanos: 20))
        #expect(row.updateTime == Timestamp(seconds: 30, nanos: 40))
        #expect(snapshot.executionTime == Timestamp(seconds: 100, nanos: 2))
        #expect(calls.map(\.descriptor.method) == ["ExecutePipeline"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/ExecutePipeline"])
        #expect(pipelineCall.options.timeout == .seconds(19))
        #expect(stages.map { $0.name } == ["collection", "let", "select"])
        #expect(stages[2].args[1].functionValue.name == "as")
        #expect(arrayExpression.name == "array")
        #expect(subqueryStages.map { $0.name } == ["collection_group", "where", "where"])
        #expect(subqueryStages[1].args[0].functionValue.args[1].variableReferenceValue == "reviewer_name")
        #expect(subqueryStages[2].args[0].functionValue.name == "less_than")
    }

    @Test("FirestoreAdmin execute sends pipeline vector nearest")
    func testExecutePipelineSendsVectorNearest() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ExecutePipelineResponse.with {
                    $0.results = [
                        Google_Firestore_V1_Document.with {
                            $0.fields["name"] = Google_Firestore_V1_Value.with {
                                $0.stringValue = "San Francisco"
                            }
                        }
                    ]
                }
            ),
            forMethod: "ExecutePipeline"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(19), retryStrategy: .none, logLevel: .warning)
        )
        let sampleVector = FirestoreVector([1.5, 2.345])
        let pipeline = firestore.pipeline()
            .collection("cities")
            .findNearest(
                field: "embedding",
                vectorValue: sampleVector,
                distanceMeasure: .euclidean,
                limit: 10,
                distanceField: "computedDistance"
            )
            .select([.field("embedding").cosineDistance(sampleVector).as("cosineDistance")])

        let snapshot = try await firestore.execute(pipeline)
        await firestore.shutdown()

        let calls = await state.snapshot()
        let pipelineCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_ExecutePipelineRequest.self,
            from: pipelineCall
        )
        let stages = request.structuredPipeline.pipeline.stages
        let findNearestOptions = stages[1].options

        #expect(snapshot.rows.first?["name"] as? String == "San Francisco")
        #expect(calls.map(\.descriptor.method) == ["ExecutePipeline"])
        #expect(pipelineCall.options.timeout == .seconds(19))
        #expect(stages.map(\.name) == ["collection", "find_nearest", "select"])
        #expect(findNearestOptions["field"]?.fieldReferenceValue == "embedding")
        #expect(findNearestOptions["vector_value"]?.arrayValue.values.map(\.doubleValue) == sampleVector.values)
        #expect(findNearestOptions["distance_measure"]?.stringValue == "euclidean")
        #expect(findNearestOptions["limit"]?.integerValue == 10)
        #expect(findNearestOptions["distance_field"]?.stringValue == "computedDistance")
        #expect(stages[2].args.first?.functionValue.args.first?.functionValue.name == "cosine_distance")
    }

    @Test("FirestoreAdmin explain sends pipeline explain options")
    func testExplainPipelineSendsExplainOptions() async throws {
        let state = RecordingTransportState()
        let explainStats = try Self.makePipelineExplainStats(#"{"plan":"scan"}"#)
        try await state.enqueueResponseParts(
            Self.responseParts([
                Google_Firestore_V1_ExecutePipelineResponse.with {
                    $0.results = [
                        Google_Firestore_V1_Document.with {
                            $0.fields["name"] = Google_Firestore_V1_Value.with {
                                $0.stringValue = "Alice"
                            }
                        }
                    ]
                    $0.executionTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 100
                        $0.nanos = 2
                    }
                },
                Google_Firestore_V1_ExecutePipelineResponse.with {
                    $0.explainStats = explainStats
                }
            ]),
            forMethod: "ExecutePipeline"
        )
        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(19), retryStrategy: .none, logLevel: .warning)
        )
        let pipeline = firestore.pipeline()
            .collection("reviewers")
            .limit(5)

        let result = try await firestore.explain(pipeline, options: .analyzeJSON)
        await firestore.shutdown()

        let calls = await state.snapshot()
        let pipelineCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_ExecutePipelineRequest.self,
            from: pipelineCall
        )
        let explainOptions = try #require(request.structuredPipeline.options["explain_options"]?.mapValue.fields)

        #expect(result.snapshot?.rows.first?["name"] as? String == "Alice")
        #expect(result.stats.outputFormat == .json)
        #expect(result.stats.json == #"{"plan":"scan"}"#)
        #expect(calls.map(\.descriptor.method) == ["ExecutePipeline"])
        #expect(pipelineCall.options.timeout == .seconds(19))
        #expect(request.structuredPipeline.pipeline.stages.map(\.name) == ["collection", "limit"])
        #expect(explainOptions["mode"]?.stringValue == "analyze")
        #expect(explainOptions["output_format"]?.stringValue == "JSON")
    }

    @Test("DocumentReference listCollections paginates ListCollectionIds RPC")
    func testListCollectionsPaginatesListCollectionIDsRPC() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ListCollectionIdsResponse.with {
                    $0.collectionIds = ["posts"]
                    $0.nextPageToken = "next-page"
                }
            ),
            forMethod: "ListCollectionIds"
        )
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ListCollectionIdsResponse.with {
                    $0.collectionIds = ["comments"]
                }
            ),
            forMethod: "ListCollectionIds"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(9), retryStrategy: .none, logLevel: .warning)
        )
        let document = try firestore.document("users/user123")

        let collections = try await document.listCollections()
        await firestore.shutdown()

        let calls = await state.snapshot()
        let requests = try calls.map { call in
            try Self.decodeSingleMessage(
                Google_Firestore_V1_ListCollectionIdsRequest.self,
                from: call
            )
        }

        #expect(collections.map(\.path) == ["users/user123/posts", "users/user123/comments"])
        #expect(calls.map(\.descriptor.method) == ["ListCollectionIds", "ListCollectionIds"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == [
            "google.firestore.v1.Firestore/ListCollectionIds",
            "google.firestore.v1.Firestore/ListCollectionIds"
        ])
        #expect(calls.allSatisfy { $0.options.timeout == .seconds(9) })
        #expect(requests.map(\.parent) == [
            "projects/test-project/databases/(default)/documents/users/user123",
            "projects/test-project/databases/(default)/documents/users/user123"
        ])
        #expect(requests.map(\.pageToken) == ["", "next-page"])
    }

    @Test("CollectionReference listDocuments paginates ListDocuments RPC")
    func testListDocumentsPaginatesListDocumentsRPC() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ListDocumentsResponse.with {
                    $0.documents = [
                        Google_Firestore_V1_Document.with {
                            $0.name = "projects/test-project/databases/(default)/documents/organizations/org123/users/user123"
                        }
                    ]
                    $0.nextPageToken = "next-page"
                }
            ),
            forMethod: "ListDocuments"
        )
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ListDocumentsResponse.with {
                    $0.documents = [
                        Google_Firestore_V1_Document.with {
                            $0.name = "projects/test-project/databases/(default)/documents/organizations/org123/users/missing"
                        }
                    ]
                }
            ),
            forMethod: "ListDocuments"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(10), retryStrategy: .none, logLevel: .warning)
        )
        let collection = try firestore.collection("organizations/org123/users")

        let documents = try await collection.listDocuments(
            pageSize: 1,
            readTime: Timestamp(seconds: 100, nanos: 200)
        )
        await firestore.shutdown()

        let calls = await state.snapshot()
        let requests = try calls.map { call in
            try Self.decodeSingleMessage(
                Google_Firestore_V1_ListDocumentsRequest.self,
                from: call
            )
        }

        #expect(documents.map(\.path) == [
            "organizations/org123/users/user123",
            "organizations/org123/users/missing"
        ])
        #expect(calls.map(\.descriptor.method) == ["ListDocuments", "ListDocuments"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == [
            "google.firestore.v1.Firestore/ListDocuments",
            "google.firestore.v1.Firestore/ListDocuments"
        ])
        #expect(calls.allSatisfy { $0.options.timeout == .seconds(10) })
        #expect(requests.map(\.parent) == [
            "projects/test-project/databases/(default)/documents/organizations/org123",
            "projects/test-project/databases/(default)/documents/organizations/org123"
        ])
        #expect(requests.map(\.collectionID) == ["users", "users"])
        #expect(requests.map(\.pageSize) == [1, 1])
        #expect(requests.map(\.pageToken) == ["", "next-page"])
        #expect(requests.allSatisfy { $0.showMissing })
        #expect(requests.allSatisfy { $0.readTime.seconds == 100 && $0.readTime.nanos == 200 })
    }

    @Test("DocumentReference setData sends Commit with configured timeout")
    func testSetDataCommitUsesConfiguredTimeout() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_CommitResponse.with {
                    $0.commitTime = Google_Protobuf_Timestamp.with {
                        $0.seconds = 1
                    }
                }
            ),
            forMethod: "Commit"
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(11), retryStrategy: .none, logLevel: .warning)
        )
        let document = try firestore.document("users/user123")

        try await document.setData(["name": "Ada"])
        await firestore.shutdown()

        let calls = await state.snapshot()
        let commitCall = try #require(calls.first)
        let request = try Self.decodeSingleMessage(
            Google_Firestore_V1_CommitRequest.self,
            from: commitCall
        )

        #expect(calls.map(\.descriptor.method) == ["Commit"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/Commit"])
        #expect(commitCall.options.timeout == .seconds(11))
        #expect(request.database == "projects/test-project/databases/(default)")
        #expect(request.writes.count == 1)
        #expect(request.writes.first?.update.name == "projects/test-project/databases/(default)/documents/users/user123")
    }

    @Test("DocumentReference listener sends remove target when stream terminates")
    func testDocumentListenerSendsRemoveTargetWhenStreamTerminates() async throws {
        let state = RecordingTransportState()
        try await state.enqueueResponseParts(
            Self.responseParts(
                Google_Firestore_V1_ListenResponse.with {
                    $0.targetChange = Google_Firestore_V1_TargetChange.with {
                        $0.targetChangeType = .current
                        $0.targetIds = [1]
                    }
                }
            ),
            forMethod: "Listen",
            holdFinalStatusUntilRequestFinish: true
        )

        let firestore = FirestoreAdmin(
            projectId: "test-project",
            transport: RecordingClientTransport(state: state),
            settings: .emulator(timeout: .seconds(13), retryStrategy: .none, logLevel: .warning)
        )
        let document = try firestore.document("users/user123")

        let snapshots = try await Self.collectFirst(try await document.addSnapshotListener())
        let didSendRemoveTarget = await Self.waitUntil {
            let calls = await state.snapshot()
            guard let call = calls.first else {
                return false
            }
            let requests: [Google_Firestore_V1_ListenRequest]
            do {
                requests = try Self.decodeMessages(
                    Google_Firestore_V1_ListenRequest.self,
                    from: call
                )
            } catch {
                return false
            }
            return requests.contains { request in
                request.targetChange == .removeTarget(1)
            } && call.didFinish
        }
        await firestore.shutdown()

        let calls = await state.snapshot()
        let listenCall = try #require(calls.first)
        let requests = try Self.decodeMessages(
            Google_Firestore_V1_ListenRequest.self,
            from: listenCall
        )

        #expect(snapshots.count == 1)
        #expect(snapshots.first?.exists == false)
        #expect(calls.map(\.descriptor.method) == ["Listen"])
        #expect(calls.map(\.descriptor.fullyQualifiedMethod) == ["google.firestore.v1.Firestore/Listen"])
        #expect(listenCall.options.timeout == nil)
        let addRequest = try #require(requests.first)
        let removeRequest = try #require(requests.dropFirst().first)
        #expect(addRequest.database == "projects/test-project/databases/(default)")
        #expect(addRequest.targetChange == .addTarget(
            Google_Firestore_V1_Target.with {
                $0.documents = Google_Firestore_V1_Target.DocumentsTarget.with {
                    $0.documents = ["projects/test-project/databases/(default)/documents/users/user123"]
                }
                $0.targetID = 1
            }
        ))
        #expect(removeRequest.database == "projects/test-project/databases/(default)")
        #expect(removeRequest.targetChange == .removeTarget(1))
        #expect(listenCall.didFinish)
        #expect(didSendRemoveTarget)
    }

    @Test("Listen stream executor maps RPC errors")
    func testListenStreamExecutorMapsRPCErrors() async throws {
        let database = Database(projectId: "test-project")
        let reference = DocumentReference(
            database,
            parentPath: "users",
            documentID: "user123"
        )
        let target = ListenTargetBuilder().makeDocumentTarget(for: reference, targetID: 1)
        let stream = await FirestoreListenStreamExecutor(database: database).makeResponseStream(
            target: target,
            metadata: [:]
        ) { _, _ in
            throw RPCError(code: .unavailable, message: "Listen unavailable")
        }

        var iterator = stream.makeAsyncIterator()
        var didMapRPCError = false
        do {
            _ = try await iterator.next()
            Issue.record("Expected mapped RPC error")
        } catch FirestoreError.rpcError(let error) {
            didMapRPCError = error.code == .unavailable
                && error.message == "Listen unavailable"
        }

        #expect(didMapRPCError)
    }

    private static func responseParts<Message: SwiftProtobuf.Message>(
        _ message: Message
    ) throws -> [RPCResponsePart<[UInt8]>] {
        try responseParts([message])
    }

    private static func responseParts<Message: SwiftProtobuf.Message>(
        _ messages: [Message]
    ) throws -> [RPCResponsePart<[UInt8]>] {
        var parts: [RPCResponsePart<[UInt8]>] = [.metadata([:])]
        for message in messages {
            parts.append(.message(try message.serializedBytes()))
        }
        parts.append(.status(Status(code: .ok, message: ""), [:]))
        return parts
    }

    private static func decodeSingleMessage<Message: SwiftProtobuf.Message>(
        _ type: Message.Type,
        from call: RecordingCall
    ) throws -> Message {
        let messages = try decodeMessages(type, from: call)
        let message = try #require(messages.first)
        #expect(messages.count == 1)
        return message
    }

    private static func decodeMessages<Message: SwiftProtobuf.Message>(
        _ type: Message.Type,
        from call: RecordingCall
    ) throws -> [Message] {
        let messageBytes = call.requestParts.compactMap { part -> [UInt8]? in
            if case .message(let bytes) = part {
                return bytes
            }
            return nil
        }
        return try messageBytes.map { bytes in
            try Message(serializedBytes: bytes)
        }
    }

    private static func requestAuthorization(from call: RecordingCall) -> String? {
        for part in call.requestParts {
            if case .metadata(let metadata) = part {
                return Array(metadata[stringValues: "authorization"]).first
            }
        }
        return nil
    }

    private static func collectFirst(
        _ stream: AsyncThrowingStream<DocumentSnapshot, Error>
    ) async throws -> [DocumentSnapshot] {
        var snapshots: [DocumentSnapshot] = []
        for try await snapshot in stream {
            snapshots.append(snapshot)
            break
        }
        return snapshots
    }

    private static func waitUntil(
        _ condition: @escaping @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<40 {
            if await condition() {
                return true
            }
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                return false
            }
        }
        return false
    }

    private static func makeExplainMetrics() -> Google_Firestore_V1_ExplainMetrics {
        Google_Firestore_V1_ExplainMetrics.with {
            $0.planSummary = Google_Firestore_V1_PlanSummary.with {
                $0.indexesUsed = [
                    Google_Protobuf_Struct.with {
                        $0.fields["query_scope"] = Google_Protobuf_Value.with {
                            $0.stringValue = "Collection"
                        }
                    }
                ]
            }
            $0.executionStats = Google_Firestore_V1_ExecutionStats.with {
                $0.resultsReturned = 1
                $0.readOperations = 1
            }
        }
    }

    private static func partitionCursor(_ referenceName: String) -> Google_Firestore_V1_Cursor {
        Google_Firestore_V1_Cursor.with {
            $0.values = [
                Google_Firestore_V1_Value.with {
                    $0.referenceValue = referenceName
                }
            ]
        }
    }

    private static func makePipelineExplainStats(_ value: String) throws -> Google_Firestore_V1_ExplainStats {
        var stats = Google_Firestore_V1_ExplainStats()
        stats.data = try Google_Protobuf_Any(
            message: Google_Protobuf_StringValue.with {
                $0.value = value
            }
        )
        return stats
    }
}

private struct RecordingClientTransport: ClientTransport {
    typealias Bytes = [UInt8]

    let state: RecordingTransportState

    var retryThrottle: RetryThrottle? {
        nil
    }

    func connect() async throws {
        while await !state.isShuttingDown {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    func withStream<T: Sendable>(
        descriptor: MethodDescriptor,
        options: CallOptions,
        _ closure: (RPCStream<Inbound, Outbound>, ClientContext) async throws -> T
    ) async throws -> T {
        let callID = await state.startCall(descriptor: descriptor, options: options)
        let responseScript = try await state.consumeResponseParts(for: descriptor)
        let inbound = RPCAsyncSequence(
            wrapping: RecordingResponsePartSequence(
                state: state,
                callID: callID,
                script: responseScript
            )
        )
        let outbound = RPCWriter<RPCRequestPart<[UInt8]>>.Closable(
            wrapping: RecordingRequestWriter(state: state, callID: callID)
        )
        let stream = RPCStream(descriptor: descriptor, inbound: inbound, outbound: outbound)
        let context = ClientContext(
            descriptor: descriptor,
            remotePeer: "recording:remote",
            localPeer: "recording:local"
        )
        return try await closure(stream, context)
    }

    func config(forMethod descriptor: MethodDescriptor) -> MethodConfig? {
        nil
    }

    func beginGracefulShutdown() {
        Task {
            await state.beginShutdown()
        }
    }
}

private actor RecordingTransportState {
    private var calls: [RecordingCall] = []
    private var responseQueues: [String: [RecordingResponseScript]] = [:]
    private var shuttingDown = false

    var isShuttingDown: Bool {
        shuttingDown
    }

    func beginShutdown() {
        shuttingDown = true
    }

    func enqueueResponseParts(
        _ parts: [RPCResponsePart<[UInt8]>],
        forMethod method: String,
        holdFinalStatusUntilRequestFinish: Bool = false
    ) {
        responseQueues[method, default: []].append(
            RecordingResponseScript(
                parts: parts,
                holdFinalStatusUntilRequestFinish: holdFinalStatusUntilRequestFinish
            )
        )
    }

    func startCall(descriptor: MethodDescriptor, options: CallOptions) -> Int {
        let callID = calls.count
        calls.append(
            RecordingCall(
                descriptor: descriptor,
                options: options,
                requestParts: [],
                didFinish: false
            )
        )
        return callID
    }

    func consumeResponseParts(for descriptor: MethodDescriptor) throws -> RecordingResponseScript {
        guard var queue = responseQueues[descriptor.method], !queue.isEmpty else {
            throw RPCError(
                code: .unimplemented,
                message: "No recorded response for \(descriptor.fullyQualifiedMethod)."
            )
        }
        let parts = queue.removeFirst()
        responseQueues[descriptor.method] = queue
        return parts
    }

    func appendRequestPart(_ part: RPCRequestPart<[UInt8]>, to callID: Int) {
        calls[callID].requestParts.append(part)
    }

    func markFinished(callID: Int) {
        calls[callID].didFinish = true
    }

    func requestMessageCount(for callID: Int) -> Int {
        calls[callID].requestParts.reduce(into: 0) { count, part in
            if case .message = part {
                count += 1
            }
        }
    }

    func didFinish(callID: Int) -> Bool {
        calls[callID].didFinish
    }

    func snapshot() -> [RecordingCall] {
        calls
    }
}

private struct RecordingResponseScript: Sendable {
    var parts: [RPCResponsePart<[UInt8]>]
    var holdFinalStatusUntilRequestFinish: Bool
}

private struct RecordingCall: Sendable {
    var descriptor: MethodDescriptor
    var options: CallOptions
    var requestParts: [RPCRequestPart<[UInt8]>]
    var didFinish: Bool
}

private actor IncrementingAccessTokenProvider: AccessTokenProvider {
    let scope: any AccessScope = FirestoreAccessScope.datastore
    private var count = 0

    var tokenCount: Int {
        count
    }

    func getAccessToken(expirationDuration: TimeInterval) async throws -> String {
        count += 1
        return "token-\(count)"
    }
}

private struct RecordingRequestWriter: ClosableRPCWriterProtocol {
    typealias Element = RPCRequestPart<[UInt8]>

    let state: RecordingTransportState
    let callID: Int

    func write(_ element: RPCRequestPart<[UInt8]>) async throws {
        await state.appendRequestPart(element, to: callID)
    }

    func write(contentsOf elements: some Sequence<RPCRequestPart<[UInt8]>>) async throws {
        for element in elements {
            try await write(element)
        }
    }

    func finish() async {
        await state.markFinished(callID: callID)
    }

    func finish(throwing error: any Error) async {
        await state.markFinished(callID: callID)
    }
}

private struct RecordingResponsePartSequence: AsyncSequence, Sendable {
    typealias Element = RPCResponsePart<[UInt8]>

    let state: RecordingTransportState
    let callID: Int
    let script: RecordingResponseScript

    func makeAsyncIterator() -> Iterator {
        Iterator(state: state, callID: callID, script: script)
    }

    struct Iterator: AsyncIteratorProtocol {
        let state: RecordingTransportState
        let callID: Int
        let script: RecordingResponseScript
        var index = 0

        mutating func next() async throws -> RPCResponsePart<[UInt8]>? {
            if index == 0 {
                while await state.requestMessageCount(for: callID) == 0 {
                    try await Task.sleep(for: .milliseconds(1))
                }
            }
            guard index < script.parts.count else {
                return nil
            }
            let part = script.parts[index]
            if script.holdFinalStatusUntilRequestFinish, case .status = part {
                while await !state.didFinish(callID: callID) {
                    try await Task.sleep(for: .milliseconds(1))
                }
            }
            defer { index += 1 }
            return part
        }
    }
}
