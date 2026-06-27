import Foundation
import FirestoreRuntimeConfig
import FirestoreRuntimeSupport
import Testing
@testable import FirestoreAPI
@testable import FirestoreAdmin
@testable import FirestoreAdminServer

@Suite("Server-side API Safety Tests")
struct ServerSideAPISafetyTests {
    @Test("Compatibility decision record covers server-side SDK boundary")
    func testCompatibilityDecisionRecordCoversServerSideSDKBoundary() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let documentURL = rootURL.appending(path: "docs/FirestoreAdminCompatibility.md")
        let document = try String(contentsOf: documentURL, encoding: .utf8)
        let requiredTokens = [
            "FirestoreAdmin.collection(_:)",
            "FirestoreAdmin.document(_:)",
            "FirestoreAdmin.collectionGroup(_:)",
            "FirestoreAdminClient",
            "Server-side code depends on the narrowest Admin protocol",
            "FirestoreAdminReferenceClient",
            "FirestoreAdminWriteClient",
            "FirestoreAdminTransactionClient",
            "FirestoreAdminPipelineClient",
            "FirestoreAdminLifecycleClient",
            "Public test doubles must be able to return Admin result values",
            "FirestoreAdminWriteOperation",
            "DocumentReference`, `CollectionReference`, `CollectionGroup`, `DocumentSnapshot`, `QueryDocumentSnapshot`, `QuerySnapshot`, `PipelineQueryRow`, and `PipelineQuerySnapshot`",
            "Write-only `FieldValue` sentinels are rejected",
            "DocumentReference.setData(_:mergeFields:)",
            "DocumentReference.listCollections()",
            "FirestoreAdminWriteBatch.setData(_:forDocument:)",
            "FirestoreAdminTransaction.getDocument(_:)",
            "FirestoreAdminTransaction.create(data:forDocument:)",
            "DocumentReference.getDocument(as:)",
            "CollectionReference.getDocuments(as:)",
            "Query.getDocuments(as:)",
            "QuerySnapshot.documents(as:)",
            "DocumentSnapshot.get(...)",
            "QueryDocumentSnapshot.get(...)",
            "snapshot subscripts",
            "data(with:)",
            "`QueryDocumentSnapshot.data()` is non-optional",
            "ServerTimestampBehavior",
            "DocumentSnapshot.reference",
            "DocumentSnapshot.documentID",
            "QueryDocumentSnapshot.reference",
            "QueryDocumentSnapshot.documentID",
            "DocumentReference.getDocument(source:)",
            "CollectionReference.getDocuments(source:)",
            "Query.getDocuments(source:)",
            "FirestoreSource",
            "`FirestoreSource.cache` is rejected because server-side Admin has no local cache",
            "DocumentReference.setData(from:merge:)",
            "DocumentReference.snapshots",
            "CollectionReference.snapshots",
            "CollectionGroup.snapshots",
            "Query.snapshots",
            "snapshots(options:)",
            "addSnapshotListener(includeMetadataChanges:)",
            "addSnapshotListener(options:)",
            "`ListenSource.cache` is rejected because server-side Admin has no local cache",
            "Query.whereField(...)",
            "Query.whereFilter(_:)",
            "Filter.filter(whereField:...)",
            "Filter.orFilter(with:)",
            "Filter.andFilter(with:)",
            "FirestoreQuerySource",
            "`Query`, `CollectionReference`, and `CollectionGroup` conform to the same SDK-style filtering, ordering, cursor, and limit surface",
            "start(at:)",
            "start(after:)",
            "end(at:)",
            "end(before:)",
            "Field-value cursors ordered by `FieldPath.documentID()` are converted from SDK-style string document IDs into Firestore reference values by `QueryCompiler`",
            "limitToLast flips orders and swaps cursors",
            "start(atDocument:)",
            "start(afterDocument:)",
            "end(atDocument:)",
            "end(beforeDocument:)",
            "Document snapshot cursors use the same snapshot field lookup path",
            "Document snapshot cursors use normalized ordering",
            "the document key is always included last",
            "`QueryPredicate` is internal RPC planning state",
            "String operator query helpers are internal test/compiler conveniences",
            "Query.aggregate(_:)",
            "Collection and collection-group aggregation helpers forward through `Query.aggregate(_:)`",
            "CollectionReference.count()`, and `CollectionGroup.count()`",
            "there is no separate collection-count runtime or gRPC path",
            "Query.findNearest(...)",
            "AggregateField.count()",
            "AggregateField.sum(_:)",
            "AggregateField.average(_:)",
            "FirestoreVector",
            "FirestoreVectorDistanceMeasure",
            "StructuredQuery.FindNearest",
            "Firestore Pipeline operations",
            "FirestoreAdmin.pipeline()",
            "FirestoreAdmin.execute(_:)",
            "FirestoreAdmin.explain(_:options:)",
            "Firestore Pipeline aggregate functions",
            "Firestore Pipeline generic functions",
            "Firestore Pipeline map functions",
            "Firestore Pipeline reference functions",
            "Firestore Pipeline string functions",
            "Firestore Pipeline timestamp functions",
            "Firestore Pipeline type functions",
            "Firestore Pipeline Search stage",
            "Firestore Pipeline typed stages",
            "collection(_:)",
            "collectionGroup(_:)",
            "database()",
            "documents(_:)",
            "literals(_:)",
            "subcollection(_:)",
            "where(_:)",
            "search(query:sort:addFields:)",
            "findNearest(field:vectorValue:distanceMeasure:limit:distanceField:)",
            "limit(_:)",
            "select(_:)",
            "define(_:)",
            "aggregate(_:groups:)",
            "removeFields(_:)",
            "replaceWith(_:mode:)",
            "FirestorePipeline.update(_:)",
            "FirestorePipeline.delete()",
            "sample(count:)",
            "sample(percentage:)",
            "unnest(_:indexField:)",
            "union(with:)",
            "Firestore Pipeline typed functions",
            "PipelineValue.reference(_:)",
            "PipelineValue.documentMatches(_:)",
            "PipelineValue.score()",
            "PipelineValue.path(_:)",
            "PipelineValue.vector(_:)",
            "document_matches",
            "score",
            "array_contains",
            "array_contains_all",
            "array_contains_any",
            "array_first",
            "array_first_n",
            "conditional",
            "not_equal",
            "pow",
            "rand",
            "count_if",
            "count_distinct",
            "minimum",
            "maximum",
            "first",
            "last",
            "array_agg",
            "array_agg_distinct",
            "cosine_distance",
            "dot_product",
            "euclidean_distance",
            "manhattan_distance",
            "vector_length",
            "current_document",
            "concat",
            "length",
            "reverse",
            "lambda",
            "maximum_n",
            "minimum_n",
            "exists",
            "is_absent",
            "if_absent",
            "is_error",
            "if_error",
            "error",
            "map_get",
            "map_set",
            "map_remove",
            "map_merge",
            "current_context",
            "map_keys",
            "map_values",
            "map_entries",
            "byte_length",
            "char_length",
            "starts_with",
            "ends_with",
            "like",
            "regex_contains",
            "regex_match",
            "string_concat",
            "string_contains",
            "string_index_of",
            "to_upper",
            "to_lower",
            "substring",
            "string_reverse",
            "string_repeat",
            "string_replace_all",
            "string_replace_one",
            "trim",
            "ltrim",
            "rtrim",
            "split",
            "current_timestamp",
            "timestamp_trunc",
            "PipelineTimestampGranularity.week(startingOn:)",
            "PipelineTimestampPart.week(startingOn:)",
            "unix_micros_to_timestamp",
            "unix_millis_to_timestamp",
            "unix_seconds_to_timestamp",
            "timestamp_add",
            "timestamp_sub",
            "timestamp_to_unix_micros",
            "timestamp_to_unix_millis",
            "timestamp_to_unix_seconds",
            "timestamp_diff",
            "timestamp_extract",
            "type",
            "is_type",
            "path",
            "vector",
            "collection_id",
            "document_id",
            "parent",
            "reference_slice",
            "array_filter",
            "array_transform",
            "array_get",
            "array_index_of",
            "array_index_of_all",
            "array_last",
            "array_last_n",
            "array_length",
            "array_reverse",
            "array_slice",
            "join",
            "switch_on",
            "PipelineValue.currentDocument()",
            "PipelineValue.lambda(parameters:body:)",
            "FirestorePipeline.toArrayExpression()",
            "FirestorePipeline.toScalarExpression()",
            "Subqueries are represented through array/scalar wrappers over nested Pipeline values",
            "Firestore Pipeline `find_nearest` and vector operations",
            "Query Explain",
            "ExplainOptions",
            "Query.explain(options:)",
            "Query.explainAggregation(_:options:)",
            "FirestoreExplainMetrics",
            "Pipeline Explain",
            "PipelineExplainOptions",
            "PipelineExplainStats",
            "Native Firestore GeoQuery solution",
            "FirestoreGeoHash.encode(_:)",
            "Firestore Enterprise MongoDB-compatible geo queries",
            "Native GeoQuery support and Firestore Enterprise MongoDB-compatible geo queries are separate responsibilities",
            "FirestoreMongoCompatibility.md",
            "FirestoreModuleSeparationPlan.md",
            "2dsphere",
            "$near",
            "Native Query, GeoQuery, and Pipeline source files do not contain Mongo-compatible `$near`, `2dsphere`, or Mongo facade concepts",
            "Visibility=Package",
            "`Visibility=Internal` only works while generated files and RPC/transport code are compiled in one target",
            "`Visibility=Public` must not become the default public API escape hatch",
            "`FirestoreProtobuf` and `FirestoreGRPCStubs` as non-product target dependencies",
            "The preferred server-side application import is the `FirestoreAdminServer` product",
            "`FirestoreAdminServer` does not re-export it",
            "New MongoDB-compatible work should depend on the explicit `FirestoreMongoCore` product",
            "Offline persistence, local cache, `clearPersistence()`",
            "`disableNetwork()` / `enableNetwork()`",
            "RPC Boundary Contract",
            "Low-level Firestore write RPCs are not public API",
            "generated `createDocument`, `updateDocument`, `deleteDocument`, or `write` methods",
            "Individual document writes, atomic batches, and transactions must compile through `WriteCompiler` to `Commit`",
            "non-atomic bulk writes must compile through `BatchWriteCompiler` to `BatchWrite`",
            "`FirestoreAdminGRPCBootstrap` validates authentication before transport startup",
            "disabled authentication is accepted only for emulator settings and is rejected for Google APIs hosts",
            "DocumentReference and CollectionReference qualified resource names are owned by core reference types",
            "Runtime protocol conformance, database ownership validation, and operation dispatch only",
            "Internal write intent data only",
            "Commit execution is delegated through the injected runtime commit handler",
            "BatchWrite execution is delegated through the injected runtime",
            "GetDocument, BatchGetDocuments, ListDocuments, and ListCollectionIds request construction",
            "BeginTransaction and Rollback request construction",
            "BatchWrite request construction and duplicate document validation",
            "BatchWrite per-write status mapping",
            "`QueryPredicate` to `StructuredQuery.Filter` construction",
            "GetDocument, BatchGetDocuments, RunQuery, RunAggregationQuery, ListDocuments, and ListCollectionIds response mapping",
            "Pipeline typed stage, Pipeline input stage shape validation, Pipeline input-stage ordering, `subcollection(...)` subquery context validation, Pipeline Search first non-input stage validation, known transformation stage shape validation, vector nearest option type validation, DML output stage terminal validation, function, timestamp value, GeoPoint value, document reference value, field reference normalization, option/variable/lambda/path/vector/geo_distance function validation, aggregate, sort, vector nearest, nested subquery, and Pipeline Explain option request construction",
            "`path` function argument shape",
            "`vector` function array shape",
            "PipelineCompiler validates stage option, function option, variable, lambda parameter, `path` function argument shape, `vector` function array shape, `geo_distance` function argument count, and document reference database ownership before RPC encoding",
            "Pipeline compiler tests cover typed document, literal input stage validation, input-stage ordering, `subcollection(...)` subquery context validation, arithmetic, array, lambda, control-flow, debugging, generic, logical, map, string, timestamp, type, reference, transform stage shape validation, Pipeline Search stage, Pipeline geospatial distance expression encoding, DML output stage, aggregate, sort, vector nearest option type validation, vector functions, and nested subquery request construction",
            "ExecutePipeline response mapping into pipeline rows",
            "field reference normalization",
            "stage options, function options, variables, and lambda parameters are validated before RPC encoding",
            "Finite RPC execution policy and Commit's explicit no-automatic-retry policy",
            "Listen request stream buffering, add/remove target request sequencing, and request stream finishing",
            "Listen reconnect, resume token, and full-resync control. It consumes protobuf Listen responses and protobuf-free `FirestoreError` values",
            "aggregation field path normalization",
            "Create writes encode `current_document.exists == false`",
            "update writes encode `current_document.exists == true`",
            "authorization metadata, protobuf request wrapping, gRPC client calls",
            "Generated protobuf and gRPC symbols are internal implementation details",
            "Firestore RPC implementation audit",
            "generated client convenience method rule",
            "low-level write RPC boundary",
            "Commit retry policy",
            "BatchWrite non-atomic bulk write contract",
            "transaction `retry_transaction` behavior",
            "transaction read/commit/rollback request contracts",
            "aggregation request contracts",
            "ExecutePipeline request contracts",
            "ExecutePipeline Explain request contracts",
            "Pipeline subquery encoding",
            "Listen authorization refresh behavior",
            "`CallOptions.timeout` usage",
            "`DocumentReference.listCollections()` ownership",
            "`CollectionReference.listDocuments()` ownership",
            "`ListDocuments` and `ListCollectionIds` pagination contracts",
            "Listen add/remove target payloads",
            "Listen streaming response bridge",
            "remove-target request before the request writer finishes",
            "Removed Pre-Stable Aliases",
            "Pre-stable source-compatibility aliases have been removed from the public API",
            "must not construct protobuf requests",
            "must not call gRPC clients directly",
            "Removed pre-stable aliases are absent from public Admin source files",
            "`QueryPredicate` and string operator query helpers are not public API",
            "`FirestoreQuerySource` is the shared public query-builder contract for `Query`, `CollectionReference`, and `CollectionGroup`",
            "`FirestoreQuerySource` default implementations own shared filter and document ID methods",
            "query and collection source files must not duplicate them",
            "The obsolete internal `WriteBatch.swift` implementation is removed",
            "Admin batch commit forwards buffered `WriteData` directly to the transaction runtime",
            "`FirestoreAdminWriteBuffer` owns Admin write staging and database validation",
            "`FirestoreAdminBulkWriter` keeps non-atomic BatchWrite separate from `FirestoreAdminWriteBatch.commit()`",
            "`FirestoreBulkWriteResult`",
            "Query predicate protobuf filter construction stays in the RPC compiler layer",
            "`CollectionGroup.partitionedQueries(partitionPointCount:pageSize:readTime:)`",
            "`FirestoreRPC/PartitionQueryCompiler.swift`",
            "`FirestoreRPC/PartitionQueryResponseMapper.swift`",
            "Runtime contract tests decode actual protobuf request bodies",
            "GetDocument, RunQuery, RunQuery vector nearest, RunQuery Explain, RunAggregationQuery, RunAggregationQuery Explain, ExecutePipeline, ExecutePipeline vector nearest, ExecutePipeline Explain, PartitionQuery, BatchWrite, ListDocuments, ListCollectionIds, Commit, Listen, BeginTransaction, BatchGetDocuments, and Rollback",
            "Firestore emulator integration covers `limit(toLast:)` document snapshot cursor result ordering",
            "Firestore emulator integration covers compound AND/OR filters and array-membership OR branches"
        ]

        for token in requiredTokens {
            #expect(document.contains(token), "Compatibility decision record should contain \(token).")
        }
    }

    @Test("AggregateField representation remains compiler-owned")
    func testAggregateFieldRepresentationRemainsCompilerOwned() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/AggregateField.swift"),
            encoding: .utf8
        )

        #expect(source.contains("public struct AggregateField"))
        #expect(source.contains("enum Operation: String, Sendable"))
        #expect(!source.contains("public enum Operation"))
        #expect(!source.contains("public let operation"))
        #expect(!source.contains("public let fieldPath"))
        #expect(!source.contains("public let alias"))
        #expect(source.contains("public static func count("))
        #expect(source.contains("public static func sum("))
        #expect(source.contains("public static func average("))
    }

    @Test("Pipeline APIs cover official function and stage names")
    func testPipelineAPIsCoverOfficialFunctionAndStageNames() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let pipelineValueSourcePaths = [
            "Sources/FirestorePipeline/PipelineValue.swift",
            "Sources/FirestorePipeline/PipelineValue+CoreExpressions.swift",
            "Sources/FirestorePipeline/PipelineValue+NumericComparison.swift",
            "Sources/FirestorePipeline/PipelineValue+Logic.swift",
            "Sources/FirestorePipeline/PipelineValue+Collections.swift",
            "Sources/FirestorePipeline/PipelineValue+Strings.swift",
            "Sources/FirestorePipeline/PipelineValue+Timestamps.swift",
            "Sources/FirestorePipeline/PipelineValue+ReferenceVectorAggregation.swift"
        ]
        let pipelineValueSource = try pipelineValueSourcePaths.map { sourcePath in
            try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
        }.joined(separator: "\n")
        let pipelineSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestorePipeline/FirestorePipeline.swift"),
            encoding: .utf8
        )
        let pipelineStageSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestorePipeline/PipelineStage.swift"),
            encoding: .utf8
        )
        let compilerSourcePaths = [
            "Sources/FirestorePipelineRPC/PipelineCompiler.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+Pipeline.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+Value.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+FunctionValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageArgumentValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageOrderValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageValidationHelpers.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+VectorStageValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+Explain.swift"
        ]
        let compilerSource = try compilerSourcePaths.map { sourcePath in
            try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
        }.joined(separator: "\n")
        let pipelineExplainStatsSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestorePipeline/PipelineExplainStats.swift"),
            encoding: .utf8
        )

        let officialFunctionNames = Set([
            "abs",
            "add",
            "and",
            "array",
            "array_agg",
            "array_agg_distinct",
            "array_concat",
            "array_contains",
            "array_contains_all",
            "array_contains_any",
            "array_filter",
            "array_first",
            "array_first_n",
            "array_get",
            "array_index_of",
            "array_index_of_all",
            "array_last",
            "array_last_n",
            "array_length",
            "array_reverse",
            "array_slice",
            "array_transform",
            "average",
            "byte_length",
            "ceil",
            "char_length",
            "cmp",
            "collection_id",
            "concat",
            "conditional",
            "cosine_distance",
            "count",
            "count_distinct",
            "count_if",
            "current_context",
            "current_document",
            "current_timestamp",
            "divide",
            "document_id",
            "dot_product",
            "ends_with",
            "equal",
            "equal_any",
            "error",
            "euclidean_distance",
            "exists",
            "exp",
            "first",
            "floor",
            "geo_distance",
            "greater_than",
            "greater_than_or_equal",
            "if_absent",
            "if_error",
            "if_null",
            "is_absent",
            "is_error",
            "is_type",
            "join",
            "last",
            "length",
            "less_than",
            "less_than_or_equal",
            "like",
            "ln",
            "log",
            "log10",
            "ltrim",
            "manhattan_distance",
            "map",
            "map_entries",
            "map_get",
            "map_keys",
            "map_merge",
            "map_remove",
            "map_set",
            "map_values",
            "maximum",
            "maximum_n",
            "minimum",
            "minimum_n",
            "mod",
            "multiply",
            "nor",
            "not",
            "not_equal",
            "not_equal_any",
            "or",
            "parent",
            "pow",
            "rand",
            "reference_slice",
            "regex_contains",
            "regex_match",
            "reverse",
            "round",
            "rtrim",
            "split",
            "sqrt",
            "starts_with",
            "string_concat",
            "string_contains",
            "string_index_of",
            "string_repeat",
            "string_replace_all",
            "string_replace_one",
            "string_reverse",
            "substring",
            "subtract",
            "sum",
            "switch_on",
            "timestamp_add",
            "timestamp_diff",
            "timestamp_extract",
            "timestamp_sub",
            "timestamp_to_unix_micros",
            "timestamp_to_unix_millis",
            "timestamp_to_unix_seconds",
            "timestamp_trunc",
            "to_lower",
            "to_upper",
            "trim",
            "trunc",
            "type",
            "unix_micros_to_timestamp",
            "unix_millis_to_timestamp",
            "unix_seconds_to_timestamp",
            "vector_length",
            "xor"
        ])
        #expect(officialFunctionNames.count == 129)

        for functionName in officialFunctionNames {
            #expect(
                pipelineValueSource.contains(".function(\"\(functionName)\""),
                "PipelineValue should expose or encode official Pipeline function \(functionName)."
            )
        }

        let officialStageNames = [
            "add_fields",
            "aggregate",
            "collection",
            "collection_group",
            "database",
            "delete",
            "distinct",
            "documents",
            "find_nearest",
            "let",
            "limit",
            "literals",
            "offset",
            "remove_fields",
            "replace_with",
            "sample",
            "search",
            "select",
            "sort",
            "subcollection",
            "union",
            "unnest",
            "update",
            "where"
        ]

        for stageName in officialStageNames {
            #expect(
                pipelineSource.contains("stage(\"\(stageName)\""),
                "FirestorePipeline should expose official Pipeline stage \(stageName)."
            )
            #expect(
                compilerSource.contains("case \"\(stageName)\""),
                "PipelineCompiler should validate official Pipeline stage \(stageName)."
            )
        }

        #expect(pipelineSource.contains("public func stage("))
        #expect(!pipelineSource.contains("public init(stages:"))
        #expect(!pipelineSource.contains("public let stages"))
        #expect(!pipelineStageSource.contains("public struct PipelineStage"))
        #expect(!pipelineStageSource.contains("public init("))
        #expect(!pipelineStageSource.contains("public let name"))
        #expect(!pipelineStageSource.contains("public let arguments"))
        #expect(!pipelineStageSource.contains("public let options"))
        #expect(pipelineValueSource.contains("public struct PipelineValue"))
        #expect(pipelineValueSource.contains("indirect enum Storage"))
        #expect(pipelineValueSource.contains("let storage: Storage"))
        #expect(!pipelineValueSource.contains("public indirect enum PipelineValue"))
        #expect(!pipelineValueSource.contains("public enum PipelineValue"))
        #expect(!pipelineValueSource.contains("public let storage"))
        #expect(!pipelineValueSource.contains("public var storage"))
        #expect(!pipelineValueSource.contains("public init(_ storage"))
        #expect(!pipelineValueSource.contains("public static func pipeline("))
        #expect(pipelineValueSource.contains("public static func function("))
        #expect(!pipelineExplainStatsSource.contains("public let rawTypeURL"))
        #expect(!pipelineExplainStatsSource.contains("public let rawData"))
        #expect(!pipelineExplainStatsSource.contains("public init(\n        outputFormat: PipelineExplainOutputFormat,\n        text: String?,\n        json: String?,\n        rawTypeURL: String?,"))
    }

    @Test("Mongo-compatible responsibility boundary stays separate")
    func testMongoCompatibleResponsibilityBoundaryStaysSeparate() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let boundaryDocument = try String(
            contentsOf: rootURL.appending(path: "docs/FirestoreMongoCompatibility.md"),
            encoding: .utf8
        )
        let requiredTokens = [
            "Status: Initial boundary implemented",
            "MongoDB-compatible Firestore APIs are implemented through a separate boundary",
            "FirestoreMongoCore",
            "FirestoreMongoGeoNearQuery",
            "FirestoreMongoGeoIndex",
            "Mongo query document builders",
            "Future Mongo-compatible transport",
            "BSON-like query documents",
            "`$near`",
            "`$geometry`",
            "`2dsphere`",
            "GeoJSON query documents",
            "must not be added to Native `QueryPredicate`",
            "should not call `QueryCompiler`",
            "should not call `QueryPredicateFilterCompiler`",
            "should not call `PipelineCompiler`",
            "should not call `FirestoreGeoQuery`"
        ]

        for token in requiredTokens {
            #expect(boundaryDocument.contains(token), "Mongo-compatible boundary should contain \(token).")
        }

        let packageSource = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let mongoExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreMongoCoreExports.swift"),
            encoding: .utf8
        )
        let adminServerExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAdminServer/FirestoreAdminServerExports.swift"),
            encoding: .utf8
        )
        let apiExportDirectory = rootURL.appending(path: "Sources/FirestoreAPI")
        let apiExportFileNames = try FileManager.default
            .contentsOfDirectory(atPath: apiExportDirectory.path())
            .filter { $0.hasSuffix("Exports.swift") }
            .sorted()
        let apiExportSources = try apiExportFileNames.map { fileName in
            try String(
                contentsOf: apiExportDirectory.appending(path: fileName),
                encoding: .utf8
            )
        }
        let actualAPIExports = Set(
            apiExportSources
                .flatMap { source in
                    source
                        .split(whereSeparator: \.isNewline)
                        .map(String.init)
                        .filter { !$0.isEmpty }
                }
        )
        let expectedAPIExports = Set([
            "@_exported import FirestoreAdmin",
            "@_exported import FirestoreAdminCodable",
            "@_exported import FirestoreAdminGRPCBootstrap",
            "@_exported import FirestoreAuth",
            "@_exported import FirestoreAuthCore",
            "@_exported import FirestoreCodable",
            "@_exported import FirestoreCore",
            "@_exported import FirestoreGeoQuery",
            "@_exported import FirestoreMongoCore",
            "@_exported import FirestorePipeline",
            "@_exported import FirestoreRuntimeConfig"
        ])

        #expect(packageSource.components(separatedBy: ".library(").count - 1 == 3)
        #expect(packageSource.contains("name: \"FirestoreAPI\",\n            targets: [\"FirestoreAPI\"]"))
        #expect(packageSource.contains("name: \"FirestoreAdminServer\",\n            targets: [\"FirestoreAdminServer\"]"))
        #expect(packageSource.contains("name: \"FirestoreMongoCore\",\n            targets: [\"FirestoreMongoCore\"]"))
        #expect(packageSource.contains("name: \"FirestoreMongoCore\""))
        #expect(packageSource.contains("\"FirestoreMongoCore\""))
        #expect(packageSource.contains("name: \"FirestoreAdminServer\""))
        #expect(packageSource.contains("targets: [\"FirestoreAdminServer\"]"))
        #expect(mongoExportSource.contains("@_exported import FirestoreMongoCore"))
        #expect(
            actualAPIExports == expectedAPIExports,
            "FirestoreAPI should remain the exact compatibility re-export surface."
        )

        let requiredAdminServerExports = [
            "@_exported import FirestoreAdmin",
            "@_exported import FirestoreAdminCodable",
            "@_exported import FirestoreAdminGRPCBootstrap",
            "@_exported import FirestoreAuth",
            "@_exported import FirestoreAuthCore",
            "@_exported import FirestoreCodable",
            "@_exported import FirestoreCore",
            "@_exported import FirestoreGeoQuery",
            "@_exported import FirestorePipeline",
            "@_exported import FirestoreRuntimeConfig"
        ]
        for token in requiredAdminServerExports {
            #expect(adminServerExportSource.contains(token), "FirestoreAdminServer should re-export \(token).")
        }
        let actualAdminServerExports = Set(
            adminServerExportSource
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { !$0.isEmpty }
        )
        #expect(
            actualAdminServerExports == Set(requiredAdminServerExports),
            "FirestoreAdminServer should expose exactly the curated server-side import surface."
        )

        let forbiddenAdminServerExports = [
            "@_exported import FirestoreMongoCore",
            "@_exported import FirestoreRPC",
            "@_exported import FirestorePipelineRPC",
            "@_exported import FirestoreGRPCTransport",
            "@_exported import FirestoreProtobuf",
            "@_exported import FirestoreGRPCStubs",
            "@_exported import FirestoreRuntimeSupport"
        ]
        for token in forbiddenAdminServerExports {
            #expect(!adminServerExportSource.contains(token), "FirestoreAdminServer should not re-export \(token).")
        }

        let adminServerTargetMarker = "        .target(\n            name: \"FirestoreAdminServer\""
        guard
            let adminServerTargetStart = packageSource.range(of: adminServerTargetMarker),
            let adminServerTargetEnd = packageSource[adminServerTargetStart.upperBound...].range(of: "        .testTarget(")
        else {
            Issue.record("Package.swift should contain a FirestoreAdminServer target before the test target.")
            return
        }
        let adminServerTargetBlock = String(
            packageSource[adminServerTargetStart.lowerBound..<adminServerTargetEnd.lowerBound]
        )
        let forbiddenAdminServerDependencies = [
            "\"FirestoreMongoCore\"",
            "\"FirestoreRPC\"",
            "\"FirestorePipelineRPC\"",
            "\"FirestoreGRPCTransport\"",
            "\"FirestoreProtobuf\"",
            "\"FirestoreGRPCStubs\"",
            "\"FirestoreRuntimeSupport\""
        ]
        for token in forbiddenAdminServerDependencies {
            #expect(!adminServerTargetBlock.contains(token), "FirestoreAdminServer should not directly depend on \(token).")
        }

        let mongoSourcePaths = [
            "Sources/FirestoreMongoCore/FirestoreMongoValue.swift",
            "Sources/FirestoreMongoCore/FirestoreMongoGeoJSONPoint.swift",
            "Sources/FirestoreMongoCore/FirestoreMongoGeoNearQuery.swift",
            "Sources/FirestoreMongoCore/FirestoreMongoGeoIndex.swift"
        ]
        let mongoSource = try mongoSourcePaths.map { sourcePath in
            try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
        }.joined(separator: "\n")
        for token in ["$near", "$geometry", "$maxDistance", "$minDistance", "2dsphere", "GeoJSON"] {
            #expect(mongoSource.contains(token), "FirestoreMongoCore should own \(token).")
        }

        let forbiddenMongoCoreTokens = [
            "import FirestoreGeoQuery",
            "import FirestorePipeline",
            "import FirestoreRPC",
            "import FirestorePipelineRPC",
            "import FirestoreProtobuf",
            "import FirestoreGRPCStubs",
            "import FirestoreGRPCTransport",
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "Google_Firestore",
            "Google_Protobuf",
            "SwiftProtobuf",
            "ClientTransport",
            "RPCError",
            "StructuredQuery",
            "ExecutePipeline",
            "QueryCompiler",
            "QueryPredicateFilterCompiler",
            "PipelineCompiler"
        ]
        for token in forbiddenMongoCoreTokens {
            #expect(!mongoSource.contains(token), "FirestoreMongoCore should not depend on \(token).")
        }

        let nativeSourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdmin.swift",
            "Sources/FirestoreCore/Query.swift",
            "Sources/FirestoreCore/QueryPredicate.swift",
            "Sources/FirestoreGeoQuery/FirestoreGeoQuery.swift",
            "Sources/FirestorePipeline/FirestorePipeline.swift",
            "Sources/FirestorePipeline/PipelineValue.swift",
            "Sources/FirestorePipeline/PipelineValue+CoreExpressions.swift",
            "Sources/FirestorePipeline/PipelineValue+NumericComparison.swift",
            "Sources/FirestorePipeline/PipelineValue+Logic.swift",
            "Sources/FirestorePipeline/PipelineValue+Collections.swift",
            "Sources/FirestorePipeline/PipelineValue+Strings.swift",
            "Sources/FirestorePipeline/PipelineValue+Timestamps.swift",
            "Sources/FirestorePipeline/PipelineValue+ReferenceVectorAggregation.swift",
            "Sources/FirestoreRPC/QueryCompiler.swift",
            "Sources/FirestoreRPC/QueryCompiler+Aggregation.swift",
            "Sources/FirestoreRPC/QueryCompiler+Cursor.swift",
            "Sources/FirestoreRPC/QueryCompiler+Explain.swift",
            "Sources/FirestoreRPC/QueryCompiler+Vector.swift",
            "Sources/FirestoreRPC/QueryPredicateFilterCompiler.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+Pipeline.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+Value.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+FunctionValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageArgumentValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageOrderValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+StageValidationHelpers.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+VectorStageValidation.swift",
            "Sources/FirestorePipelineRPC/PipelineCompiler+Explain.swift",
            "Sources/FirestorePipelineRPC/PipelineResponseMapper.swift"
        ]
        let forbiddenTokens = [
            "FirestoreMongo",
            "Mongo-compatible",
            "MongoDB-compatible",
            "BSON",
            "GeoJSON",
            "$near",
            "2dsphere"
        ]

        for sourcePath in nativeSourcePaths {
            let source = try String(
                contentsOf: rootURL.appending(path: sourcePath),
                encoding: .utf8
            )
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should keep \(token) out of Native Firestore APIs.")
            }
        }
    }

    @Test("README test count matches Swift Testing declarations")
    func testREADMETestCountMatchesSwiftTestingDeclarations() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let testsURL = rootURL.appending(path: "Tests/FirebaseAPITests")
        let readme = try String(contentsOf: rootURL.appending(path: "README.md"), encoding: .utf8)
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: testsURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirebaseAPITests directory should be readable.")
            return
        }

        let testToken = "@T" + "est("
        let suiteToken = "@S" + "uite("
        var testCount = 0
        var suiteCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            testCount += source.components(separatedBy: testToken).count - 1
            suiteCount += source.components(separatedBy: suiteToken).count - 1
        }

        #expect(readme.contains("\(testCount) tests across \(suiteCount) suites"))
    }

    @Test("Release readiness script preserves boundary checks")
    func testReleaseReadinessScriptPreservesBoundaryChecks() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let script = try String(
            contentsOf: rootURL.appending(path: "scripts/check-release-readiness.sh"),
            encoding: .utf8
        )
        let readme = try String(
            contentsOf: rootURL.appending(path: "README.md"),
            encoding: .utf8
        )
        let liveSmokeScript = try String(
            contentsOf: rootURL.appending(path: "scripts/run-live-firestore-smoke.sh"),
            encoding: .utf8
        )
        let liveSmokeTest = try String(
            contentsOf: rootURL.appending(path: "Tests/FirebaseAPITests/FirestoreLiveIntegrationTests.swift"),
            encoding: .utf8
        )
        let completionAudit = try String(
            contentsOf: rootURL.appending(path: "docs/FirestoreAdminCompletionAudit.md"),
            encoding: .utf8
        )
        let requiredScriptTokens = [
            "git diff --check",
            "XCODE_SCHEME=\"${XCODE_SCHEME:-FirebaseAPI-Package}\"",
            "Checking legacy implementation names",
            "legacy gPRC typo and obsolete Admin facade type names must not return",
            "gPRC|FirestoreAdminFacade|AdminFacade",
            "RPC compiler/reducer files must not depend on grpc-swift transport types",
            "Checking gRPC request wrapper ownership",
            "finite ClientRequest wrappers must stay in FirestoreGRPCRuntime+FiniteRequest.swift",
            "streaming ClientRequest wrappers must stay in FirestoreListenStreamExecutor.swift",
            "Checking generated gRPC client call ownership",
            "generated Firestore client calls must stay in FirestoreGRPCRuntime operation wrappers",
            "low-level write generated client calls must not be used by hand-written transport code",
            "hand-written source must not use forbidden Swift patterns",
            "!Sources/FirestoreProtobuf/Proto/**",
            "!Sources/FirestoreGRPCStubs/Proto/**",
            "protobuf implementation types must stay out of core public source",
            "Sources/FirestoreAdminCodable",
            "Checking runtime configuration boundaries",
            "FirestoreCore must not own server runtime configuration types",
            "FirestoreRuntimeConfig must not depend on transport, auth implementations, RPC compilers, protobuf, Pipeline, or logging",
            "Mongo-compatible constructs must stay out of Native Firestore source",
            "!Sources/FirestoreAPI/FirestoreMongoCoreExports.swift",
            "Checking Mongo-compatible core boundaries",
            "FirestoreMongoCore must not depend on Native RPC, Pipeline RPC, Native GeoQuery, protobuf, or grpc-swift transport",
            "StructuredQuery",
            "ExecutePipeline",
            "swift package dump-symbol-graph --minimum-access-level public --skip-synthesized-members",
            "public symbol graph must not expose protobuf, gRPC transport, or internal planning symbols",
            "clearPersistence|enableNetwork|disableNetwork|waitForPendingWrites|ListenerRegistration|snapshotsInSync",
            "PersistentCache|MemoryCache|LocalCache|cacheSettings|terminate\\\\(",
            "ClientRequest",
            "where\\\\(field",
            "AggregateField\\\\.Operation",
            "AggregateField\\\",\\\"operation",
            "AggregateField\\\",\\\"fieldPath",
            "AggregateField\\\",\\\"alias",
            "PipelineValue\\\\.Storage",
            "PipelineValue\\\\.storage",
            "PipelineValue\\\\.pipeline\\\\(",
            "PipelineExplainStats\\\",\\\"rawTypeURL",
            "PipelineExplainStats\\\",\\\"rawData",
            "PipelineExplainStats\\\",\\\"init\\\\(outputFormat:text:json:rawTypeURL:rawData:\\\\)",
            "ServiceAccountCredentials\\\",\\\"privateKey",
            "ServiceAccountCredentials\\\",\\\"privateKeyId",
            "ServiceAccountCredentials\\\",\\\"tokenURI",
            "Checking live Firestore smoke diagnostics",
            "bash -n scripts/run-live-firestore-smoke.sh",
            "FIRESTORE_LIVE_DIAGNOSTICS_ONLY=1",
            "FirestoreRPCExecutor",
            "FirestoreRuntime",
            "DocumentRequestCompiler",
            "WriteCompiler",
            "ReadResponseMapper",
            "ListenStreamCoordinator",
            "WriteData",
            "xcodebuild -quiet -scheme",
            "Release readiness checks passed."
        ]

        for token in requiredScriptTokens {
            #expect(script.contains(token), "Release readiness script should contain \(token).")
        }
        #expect(readme.contains("bash scripts/check-release-readiness.sh"))
        #expect(readme.contains("xcodebuild -scheme FirebaseAPI-Package"))
        #expect(readme.contains("public symbol graph"))
        #expect(readme.contains("bash scripts/run-live-firestore-smoke.sh"))
        #expect(readme.contains("gcloud well-known ADC file"))
        #expect(readme.contains("GOOGLE_APPLICATION_CREDENTIALS"))
        #expect(readme.contains("FIRESTORE_LIVE_PROJECT_ID"))
        #expect(readme.contains("FIRESTORE_LIVE_DIAGNOSTICS_ONLY"))
        #expect(completionAudit.contains("bash scripts/run-live-firestore-smoke.sh"))
        #expect(completionAudit.contains("FIRESTORE_LIVE_DIAGNOSTICS_ONLY"))
        #expect(completionAudit.contains("SwiftPM can make transitive implementation targets visible"))
        #expect(completionAudit.contains("public API visibility, not absolute module import invisibility"))

        let requiredLiveSmokeTokens = [
            "FIRESTORE_LIVE_SMOKE",
            "FIRESTORE_LIVE_DIAGNOSTICS_ONLY",
            "Skipping live Firestore smoke",
            "Live Firestore smoke diagnostics",
            "GOOGLE_APPLICATION_CREDENTIALS: set and file exists",
            "gcloud well-known ADC file",
            "metadata server ADC: allowed fallback when running on Google Cloud",
            "warning: GOOGLE_APPLICATION_CREDENTIALS takes precedence",
            "warning: no local credential or project candidate was detected",
            "Running live Firestore smoke against production Firestore RPCs",
            "xcodebuild -quiet -scheme",
            "-only-testing:FirebaseAPITests/FirestoreLiveIntegrationTests",
            "Live Firestore smoke passed."
        ]
        for token in requiredLiveSmokeTokens {
            #expect(liveSmokeScript.contains(token), "Live smoke script should contain \(token).")
        }
        #expect(liveSmokeTest.contains("FirestoreAdmin.applicationDefaultResolvingProjectID("))
        #expect(liveSmokeTest.contains("projectId: configuration.projectID"))
        #expect(liveSmokeTest.contains("databaseId: configuration.databaseID"))
    }

    @Test("Generated protobuf and gRPC targets remain package-internal implementation targets")
    func testGeneratedProtoTargetsRemainPackageInternalImplementationTargets() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let packageManifest = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let generationScript = try String(
            contentsOf: rootURL.appending(path: "scripts/generate-firestore-protos.sh"),
            encoding: .utf8
        )

        #expect(packageManifest.contains("targets: [\"FirestoreAPI\"]"))
        #expect(packageManifest.contains("name: \"FirestoreProtobuf\""))
        #expect(packageManifest.contains("name: \"FirestoreGRPCStubs\""))
        #expect(packageManifest.contains("\"FirestoreProtobuf\""))
        #expect(packageManifest.contains("\"FirestoreGRPCStubs\""))
        #expect(!packageManifest.contains("name: \"FirestoreProtobuf\",\n            targets: [\"FirestoreProtobuf\"]"))
        #expect(!packageManifest.contains("name: \"FirestoreGRPCStubs\",\n            targets: [\"FirestoreGRPCStubs\"]"))

        #expect(generationScript.contains("OLD_PROTO_DIR=\"$ROOT_DIR/Sources/FirestoreAPI/Proto\""))
        #expect(generationScript.contains("PROTO_MESSAGE_DIR=\"$ROOT_DIR/Sources/FirestoreProtobuf/Proto\""))
        #expect(generationScript.contains("PROTO_GRPC_DIR=\"$ROOT_DIR/Sources/FirestoreGRPCStubs/Proto\""))
        #expect(generationScript.contains("--swift_opt=Visibility=Package"))
        #expect(generationScript.contains("--grpc-swift-2_opt=Visibility=Package"))
        #expect(generationScript.contains("--grpc-swift-2_opt=ExtraModuleImports=FirestoreProtobuf"))
    }

    @Test("FirestoreCore remains a protobuf-free public model target")
    func testFirestoreCoreRemainsProtobufFreePublicModelTarget() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let packageManifest = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let reexportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreCoreExports.swift"),
            encoding: .utf8
        )
        let databaseSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/Database.swift"),
            encoding: .utf8
        )
        let pathValidatorSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/FirestorePathValidator.swift"),
            encoding: .utf8
        )
        let coreRootURL = rootURL.appending(path: "Sources/FirestoreCore")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: coreRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreCore source directory should be readable.")
            return
        }

        #expect(packageManifest.contains("name: \"FirestoreCore\""))
        #expect(packageManifest.contains("\"FirestoreCore\""))
        #expect(!packageManifest.contains("name: \"FirestoreCore\",\n            targets: [\"FirestoreCore\"]"))
        #expect(reexportSource.contains("@_exported import FirestoreCore"))
        #expect(databaseSource.contains("package struct Database"))
        #expect(!databaseSource.contains("public struct Database"))
        #expect(pathValidatorSource.contains("package enum FirestorePathValidator"))
        #expect(!pathValidatorSource.contains("public enum FirestorePathValidator"))

        let forbiddenTokens = [
            "import FirestoreProtobuf",
            "import FirestoreGRPCStubs",
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "import SwiftProtobuf",
            "import Crypto",
            "import CryptoExtras",
            "import Logging",
            "FirestoreSettings",
            "FirestoreRetryStrategy",
            "FirestoreRetryHandler",
            "FirestoreRetryable",
            "FirestoreLogLevel",
            "FirestoreAuthenticationMode",
            "Google_Firestore_",
            "Google_Protobuf_",
            "ClientTransport",
            "RPCError",
            "FirestoreGRPCRuntime"
        ]
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourceURL.path()) should keep \(token) outside FirestoreCore.")
            }
        }

        #expect(checkedFileCount > 0, "FirestoreCore source files should be checked.")
    }

    @Test("Public Admin core types do not depend on gRPC transport")
    func testPublicAdminCoreTypesDoNotDependOnGRPCTransport() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdmin.swift",
            "Sources/FirestoreAdmin/FirestoreAdminClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminReferenceClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransactionClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminPipelineClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminLifecycleClient.swift",
            "Sources/FirestoreRuntimeConfig/FirestoreSetting.swift",
            "Sources/FirestoreRuntimeConfig/FirestoreRetry.swift",
            "Sources/FirestoreRuntimeConfig/FirestoreAuthenticationMode.swift",
            "Sources/FirestoreCore/DocumentReference.swift",
            "Sources/FirestoreCore/CollectionReference.swift",
            "Sources/FirestoreCore/CollectionReference+Query.swift",
            "Sources/FirestoreCore/CollectionGroup.swift",
            "Sources/FirestoreCore/CollectionGroup+Query.swift",
            "Sources/FirestoreCore/Query.swift",
            "Sources/FirestoreCore/Query+DocumentSnapshotCursor.swift",
            "Sources/FirestoreCore/DocumentSnapshot.swift",
            "Sources/FirestoreCore/QueryDocumentSnapshot.swift",
            "Sources/FirestoreCore/QuerySnapshot.swift",
            "Sources/FirestoreCore/FirestoreSnapshotSequence.swift",
            "Sources/FirestoreCore/FieldValue.swift",
            "Sources/FirestoreCore/Filter.swift",
            "Sources/FirestoreCore/FirestoreQuerySource.swift",
            "Sources/FirestoreCore/AggregateField.swift",
            "Sources/FirestoreCore/AggregateValue.swift",
            "Sources/FirestoreCore/AggregateQuerySnapshot.swift",
            "Sources/FirestoreCore/AggregateQueryExplainResult.swift",
            "Sources/FirestoreCore/FirestoreExplainOptions.swift",
            "Sources/FirestoreCore/FirestoreExplainValue.swift",
            "Sources/FirestoreCore/FirestoreExplainPlanSummary.swift",
            "Sources/FirestoreCore/FirestoreExplainExecutionStats.swift",
            "Sources/FirestoreCore/FirestoreExplainMetrics.swift",
            "Sources/FirestoreCore/QueryExplainResult.swift",
            "Sources/FirestoreCore/FirestoreVector.swift",
            "Sources/FirestoreCore/FirestoreVectorDistanceMeasure.swift",
            "Sources/FirestoreCore/FirestoreFindNearestQuery.swift",
            "Sources/FirestoreGeoQuery/FirestoreGeoHash.swift",
            "Sources/FirestoreGeoQuery/FirestoreGeoQuery.swift",
            "Sources/FirestoreGeoQuery/GeoHash.swift",
            "Sources/FirestoreGeoQuery/GeoPoint+Distance.swift",
            "Sources/FirestoreGeoQuery/GeoQueryLocationExtractor.swift",
            "Sources/FirestoreGeoQuery/GeoQueryResult.swift",
            "Sources/FirestoreCore/FirestoreSource.swift",
            "Sources/FirestoreCore/ListenSource.swift",
            "Sources/FirestoreCore/SnapshotListenOptions.swift",
            "Sources/FirestoreCore/ServerTimestampBehavior.swift",
            "Sources/FirestorePipeline/FirestorePipeline.swift",
            "Sources/FirestorePipeline/PipelineStage.swift",
            "Sources/FirestorePipeline/PipelineReplaceMode.swift",
            "Sources/FirestorePipeline/PipelineValue.swift",
            "Sources/FirestorePipeline/PipelineValue+CoreExpressions.swift",
            "Sources/FirestorePipeline/PipelineValue+NumericComparison.swift",
            "Sources/FirestorePipeline/PipelineValue+Logic.swift",
            "Sources/FirestorePipeline/PipelineValue+Collections.swift",
            "Sources/FirestorePipeline/PipelineValue+Strings.swift",
            "Sources/FirestorePipeline/PipelineValue+Timestamps.swift",
            "Sources/FirestorePipeline/PipelineValue+ReferenceVectorAggregation.swift",
            "Sources/FirestorePipeline/PipelineSwitchCase.swift",
            "Sources/FirestorePipeline/PipelineTimestampUnit.swift",
            "Sources/FirestorePipeline/PipelineTimestampGranularity.swift",
            "Sources/FirestorePipeline/PipelineTimestampPart.swift",
            "Sources/FirestorePipeline/PipelineQuerySnapshot.swift",
            "Sources/FirestorePipeline/PipelineExplainMode.swift",
            "Sources/FirestorePipeline/PipelineExplainOutputFormat.swift",
            "Sources/FirestorePipeline/PipelineExplainOptions.swift",
            "Sources/FirestorePipeline/PipelineExplainStats.swift",
            "Sources/FirestorePipeline/PipelineExplainResult.swift",
            "Sources/FirestoreCore/WriteData.swift",
            "Sources/FirestoreCore/TransactionOptions.swift",
            "Sources/FirestoreAdmin/TransactionError.swift",
            "Sources/FirestoreAdmin/FirestoreAdmin+Transaction.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteBatch.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransaction.swift",
            "Sources/FirestoreAdmin/FirestoreAdminBulkWriter.swift",
            "Sources/FirestoreCore/FirestoreBulkWriteResult.swift",
            "Sources/FirestoreCore/FirestoreBulkWriteOperationResult.swift"
        ]
        let forbiddenTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "ClientTransport",
            "GRPCCore.Metadata",
            "Firestore<Transport>",
            "FirestoreGRPCRuntime<Transport>",
            "getAccessToken()",
            "performing RPC calls",
            "Firestore instance"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should not contain \(token).")
            }
        }

        let immutableIdentitySources = [
            ("Sources/FirestoreCore/DocumentReference.swift", "public let documentID", "public var documentID"),
            ("Sources/FirestoreCore/CollectionReference.swift", "public let collectionID", "public var collectionID"),
            ("Sources/FirestoreCore/CollectionGroup.swift", "public let groupID", "public var groupID"),
            ("Sources/FirestoreCore/Query.swift", "public let collectionID", "public var collectionID")
        ]
        for (sourcePath, requiredToken, forbiddenToken) in immutableIdentitySources {
            let source = try String(
                contentsOf: rootURL.appending(path: sourcePath),
                encoding: .utf8
            )
            #expect(source.contains(requiredToken), "\(sourcePath) should expose immutable identity with \(requiredToken).")
            #expect(!source.contains(forbiddenToken), "\(sourcePath) should not expose mutable identity with \(forbiddenToken).")
        }

        let immutableResultTokens = [
            ("Sources/FirestoreCore/DocumentSnapshot.swift", "public let metadata", "public var metadata"),
            ("Sources/FirestoreCore/DocumentSnapshot.swift", "public let documentReference", "public var documentReference"),
            ("Sources/FirestoreCore/QueryDocumentSnapshot.swift", "public let documentReference", "public var documentReference"),
            ("Sources/FirestoreCore/QuerySnapshot.swift", "public let metadata", "public var metadata"),
            ("Sources/FirestoreCore/QuerySnapshot.swift", "public let documents", "public var documents"),
            ("Sources/FirestoreCore/QuerySnapshot.swift", "public let documentChanges", "public var documentChanges"),
            ("Sources/FirestoreCore/SnapshotMetadata.swift", "public let hasPendingWrites", "public var hasPendingWrites"),
            ("Sources/FirestoreCore/SnapshotMetadata.swift", "public let isFromCache", "public var isFromCache"),
            ("Sources/FirestoreCore/Timestamp.swift", "public let seconds", "public var seconds"),
            ("Sources/FirestoreCore/Timestamp.swift", "public let nanos", "public var nanos"),
            ("Sources/FirestoreCore/GeoPoint.swift", "public let latitude", "public var latitude"),
            ("Sources/FirestoreCore/GeoPoint.swift", "public let longitude", "public var longitude")
        ]
        for (sourcePath, requiredToken, forbiddenToken) in immutableResultTokens {
            let source = try String(
                contentsOf: rootURL.appending(path: sourcePath),
                encoding: .utf8
            )
            #expect(source.contains(requiredToken), "\(sourcePath) should expose immutable result state with \(requiredToken).")
            #expect(!source.contains(forbiddenToken), "\(sourcePath) should not expose mutable result state with \(forbiddenToken).")
        }
    }

    @Test("Public source text stays server-side Admin oriented")
    func testPublicSourceTextStaysServerSideAdminOriented() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceRootURL = rootURL.appending(path: "Sources/FirestoreAPI")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: sourceRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreAPI source directory should be readable.")
            return
        }

        let implementationDirectories = [
            "/Proto/",
            "/RPC/"
        ]
        let forbiddenTokens = [
            "Firestore instance",
            "`Firestore` instance",
            "FirebaseApp",
            "client app",
            "client SDK",
            "app-local state",
            "offline persistence",
            "local cache",
            "clearPersistence",
            "disableNetwork",
            "enableNetwork",
            "pending writes",
            "performing RPC calls",
            "RPC calls",
            "ClientTransport",
            "Firestore<Transport>"
        ]
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            let path = sourceURL.path()
            guard !implementationDirectories.contains(where: path.contains) else {
                continue
            }

            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(path) should keep user-facing text server-side Admin oriented and must not contain \(token).")
            }
        }

        #expect(checkedFileCount > 0, "Public source files should be checked.")
    }

    @Test("FirestoreAdminClient can be implemented with public result factories")
    func testFirestoreAdminClientCanBeImplementedWithPublicResultFactories() async throws {
        struct FakeFirestoreAdminClient: FirestoreAdminClient {
            let projectId = "fake-project"

            func collectionGroup(_ groupID: String) throws -> CollectionGroup {
                try CollectionGroup(projectId: projectId, groupID: groupID)
            }

            func collection(_ collectionPath: String) throws -> CollectionReference {
                try CollectionReference(projectId: projectId, path: collectionPath)
            }

            func document(_ documentPath: String) throws -> DocumentReference {
                try DocumentReference(projectId: projectId, path: documentPath)
            }

            func batch() -> FirestoreAdminWriteBatch {
                FirestoreAdminWriteBatch(projectId: projectId)
            }

            func bulkWriter() -> FirestoreAdminBulkWriter {
                FirestoreAdminBulkWriter(projectId: projectId)
            }

            func pipeline() -> FirestorePipeline {
                FirestorePipeline()
            }

            func execute(_ pipeline: FirestorePipeline) async throws -> PipelineQuerySnapshot {
                let reference = try document("users/ada")
                let row = try PipelineQueryRow(
                    data: [
                        "name": "Ada",
                        "score": Int64(42),
                        "location": GeoPoint(latitude: 35.681236, longitude: 139.767125),
                        "embedding": FirestoreVector([0.1, 0.2])
                    ],
                    documentReference: reference
                )
                return PipelineQuerySnapshot(rows: [row], executionTime: Timestamp(seconds: 1, nanos: 2))
            }

            func explain(
                _ pipeline: FirestorePipeline,
                options: PipelineExplainOptions
            ) async throws -> PipelineExplainResult {
                PipelineExplainResult(
                    snapshot: nil,
                    stats: PipelineExplainStats(outputFormat: .text, text: "ok", json: nil)
                )
            }

            func runTransaction<T>(
                _ transactionFunction: @escaping (FirestoreAdminTransaction) async throws -> T?,
                options: TransactionOptions
            ) async throws -> T? {
                nil
            }

            func setLogLevel(_ level: FirestoreLogLevel) { }

            func shutdown() async { }
        }

        let client: any FirestoreAdminClient = FakeFirestoreAdminClient()
        let document = try client.document("users/ada")
        let collection = try client.collection("users/ada/posts")
        let group = try client.collectionGroup("posts")
        let homepage = try #require(URL(string: "https://example.com"))
        let queryDocument = try QueryDocumentSnapshot(
            data: [
                "name": "Ada",
                "age": Int64(37),
                "profile": ["active": true],
                "homepage": homepage
            ],
            documentReference: document
        )
        let documentSnapshot = try DocumentSnapshot(
            data: ["name": "Ada", "createdAt": Date(timeIntervalSince1970: 1.25)],
            documentReference: document,
            metadata: SnapshotMetadata(hasPendingWrites: false, isFromCache: true)
        )
        let missingSnapshot = DocumentSnapshot.missing(reference: document)
        let querySnapshot = QuerySnapshot(documents: [queryDocument])
        let pipelineSnapshot = try await client.execute(client.pipeline())
        let batch = client.batch()
        batch.setData(["name": "Ada"], forDocument: document)
        try await batch.commit()
        let bulkResult = try await client
            .bulkWriter()
            .setData(["name": "Ada"], forDocument: document)
            .flush(labels: ["mode": "fake"])

        #expect(document.path == "users/ada")
        #expect(collection.path == "users/ada/posts")
        #expect(group.groupID == "posts")
        #expect(queryDocument.data()["age"] as? Int == 37)
        #expect(queryDocument.get("profile.active") as? Bool == true)
        #expect(documentSnapshot.exists)
        #expect(documentSnapshot.metadata.isFromCache)
        #expect(missingSnapshot.exists == false)
        #expect(querySnapshot.documents.count == 1)
        #expect(pipelineSnapshot.rows.count == 1)
        #expect(pipelineSnapshot.resultRows.first?.documentReference == document)
        #expect(bulkResult.results.count == 1)
        #expect(bulkResult.results.first?.document == document)
        #expect(bulkResult.results.first?.succeeded == true)
    }

    @Test("Public Admin write builders expose operation summaries for fakes")
    func testPublicAdminWriteBuildersExposeOperationSummariesForFakes() async throws {
        let document = try DocumentReference(projectId: "fake-project", path: "users/ada")
        let batch = FirestoreAdminWriteBatch(projectId: "fake-project") { operations in
            #expect(operations.count == 1)
            let operation = try #require(operations.first)
            #expect(operation.kind == .set)
            #expect(operation.document == document)
            #expect(operation.data?["name"] as? String == "Ada")
        }
        batch.setData(["name": "Ada"], forDocument: document)
        try await batch.commit()

        let bulkWriter = FirestoreAdminBulkWriter(projectId: "fake-project") { operations, labels in
            #expect(labels["mode"] == "fake")
            #expect(operations.count == 1)
            let operation = try #require(operations.first)
            #expect(operation.kind == .update)
            #expect(operation.document == document)
            return FirestoreBulkWriteResult(
                results: operations.enumerated().map { index, operation in
                    FirestoreBulkWriteOperationResult(
                        index: index,
                        document: operation.document,
                        updateTime: nil,
                        error: nil
                    )
                }
            )
        }
        bulkWriter.updateData(["score": 42], forDocument: document)
        let result = try await bulkWriter.flush(labels: ["mode": "fake"])

        #expect(result.results.count == 1)
        #expect(result.results.first?.document == document)
    }

    @Test("Narrow Admin client protocols support workflow-specific test doubles")
    func testNarrowAdminClientProtocolsSupportWorkflowSpecificTestDoubles() throws {
        struct ReferenceOnlyAdminClient: FirestoreAdminReferenceClient {
            let projectId = "fake-project"

            func collectionGroup(_ groupID: String) throws -> CollectionGroup {
                try CollectionGroup(projectId: projectId, groupID: groupID)
            }

            func collection(_ collectionPath: String) throws -> CollectionReference {
                try CollectionReference(projectId: projectId, path: collectionPath)
            }

            func document(_ documentPath: String) throws -> DocumentReference {
                try DocumentReference(projectId: projectId, path: documentPath)
            }
        }

        let client: any FirestoreAdminReferenceClient = ReferenceOnlyAdminClient()
        #expect(try client.collection("users").path == "users")
        #expect(try client.document("users/ada").path == "users/ada")
        #expect(try client.collectionGroup("posts").groupID == "posts")
    }

    @Test("Public snapshot factories reject write-only sentinels")
    func testPublicSnapshotFactoriesRejectWriteOnlySentinels() throws {
        let reference = try DocumentReference(projectId: "fake-project", path: "users/ada")

        var didThrowInvalidFieldValue = false
        do {
            _ = try QueryDocumentSnapshot(
                data: ["updatedAt": FieldValue.serverTimestamp()],
                documentReference: reference
            )
        } catch FirestoreError.invalidFieldValue {
            didThrowInvalidFieldValue = true
        } catch {
            didThrowInvalidFieldValue = false
        }

        #expect(didThrowInvalidFieldValue)
    }

    @Test("Public auth support types do not depend on gRPC transport or protobuf")
    func testPublicAuthSupportTypesDoNotDependOnGRPCTransportOrProtobuf() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let packageSource = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let sourcePaths = [
            "Sources/FirestoreAuthCore/AccessTokenProvider.swift",
            "Sources/FirestoreAuthCore/FirestoreAccessScope.swift",
            "Sources/FirestoreAuth/Auth/ServiceAccountCredentials.swift",
            "Sources/FirestoreAuth/Auth/MetadataServerAccessTokenProvider.swift",
            "Sources/FirestoreAuth/Auth/ServiceAccountAccessTokenProvider.swift",
            "Sources/FirestoreAuth/Auth/MetadataServerProjectIDProvider.swift",
            "Sources/FirestoreAuth/Auth/GoogleApplicationDefaultCredentials.swift"
        ]
        let forbiddenTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "ClientTransport",
            "GRPCCore.Metadata",
            "FirestoreGRPCRuntime",
            "ClientRequest",
            "StreamingClientRequest",
            "Google_Firestore_",
            "Google_Protobuf_",
            "SwiftProtobuf"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should not contain \(token).")
            }
        }

        let credentialsSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAuth/Auth/ServiceAccountCredentials.swift"),
            encoding: .utf8
        )
        let authExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreAuthExports.swift"),
            encoding: .utf8
        )
        let authCoreExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreAuthCoreExports.swift"),
            encoding: .utf8
        )
        var authDeclarations: [String] = []
        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let declarations = source
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { line in
                    line.hasPrefix("public struct ")
                        || line.hasPrefix("public actor ")
                        || line.hasPrefix("public enum ")
                        || line.hasPrefix("public protocol ")
                }
                .map { "\(sourcePath):\($0)" }
            authDeclarations.append(contentsOf: declarations)
        }
        let expectedAuthDeclarations = Set([
            "Sources/FirestoreAuthCore/AccessTokenProvider.swift:public protocol AccessScope: Sendable {",
            "Sources/FirestoreAuthCore/AccessTokenProvider.swift:public protocol AccessTokenProvider: Sendable {",
            "Sources/FirestoreAuthCore/FirestoreAccessScope.swift:public struct FirestoreAccessScope: AccessScope, Equatable, Sendable {",
            "Sources/FirestoreAuth/Auth/ServiceAccountCredentials.swift:public struct ServiceAccountCredentials: Codable, Equatable, Sendable {",
            "Sources/FirestoreAuth/Auth/MetadataServerAccessTokenProvider.swift:public actor MetadataServerAccessTokenProvider: AccessTokenProvider {",
            "Sources/FirestoreAuth/Auth/ServiceAccountAccessTokenProvider.swift:public actor ServiceAccountAccessTokenProvider: AccessTokenProvider {",
            "Sources/FirestoreAuth/Auth/MetadataServerProjectIDProvider.swift:public struct MetadataServerProjectIDProvider: Sendable {",
            "Sources/FirestoreAuth/Auth/GoogleApplicationDefaultCredentials.swift:public enum GoogleApplicationDefaultCredentials {"
        ])

        #expect(
            Set(authDeclarations) == expectedAuthDeclarations,
            "FirestoreAuth should expose only the curated server-side authentication surface."
        )
        #expect(credentialsSource.contains("public let projectId"))
        #expect(credentialsSource.contains("public let clientEmail"))
        #expect(!credentialsSource.contains("public let privateKey"))
        #expect(!credentialsSource.contains("public let privateKeyId"))
        #expect(!credentialsSource.contains("public let tokenURI"))
        #expect(authExportSource.contains("@_exported import FirestoreAuth"))
        #expect(authCoreExportSource.contains("@_exported import FirestoreAuthCore"))
        #expect(packageSource.contains("name: \"FirestoreAuthCore\""))
        #expect(packageSource.contains("name: \"FirestoreAuth\""))
        #expect(packageSource.contains("\"FirestoreAuthCore\""))
        #expect(packageSource.contains("\"FirestoreAuth\""))
    }

    @Test("FirestoreAdmin transport injection remains an internal test seam")
    func testFirestoreAdminTransportInjectionRemainsInternalTestSeam() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let packageSource = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let adminGRPCBootstrapSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAdminGRPCBootstrap/FirestoreAdmin+gRPC.swift"),
            encoding: .utf8
        )
        let adminExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreAdminGRPCBootstrapExports.swift"),
            encoding: .utf8
        )
        let transportFactorySource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCTransportFactory.swift"),
            encoding: .utf8
        )
        let adminSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAdmin/FirestoreAdmin.swift"),
            encoding: .utf8
        )
        let adminClientSourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdminClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminReferenceClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransactionClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminPipelineClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminLifecycleClient.swift"
        ]
        let clientSource = try adminClientSourcePaths
            .map { try String(contentsOf: rootURL.appending(path: $0), encoding: .utf8) }
            .joined(separator: "\n")

        #expect(packageSource.contains("name: \"FirestoreAdminGRPCBootstrap\""))
        #expect(packageSource.contains("\"FirestoreAdminGRPCBootstrap\""))
        #expect(adminExportSource.contains("@_exported import FirestoreAdminGRPCBootstrap"))
        #expect(adminSource.contains("package init("))
        #expect(!adminSource.contains("import FirestoreGRPCTransport"))
        #expect(!adminSource.contains("import FirestoreAuth"))
        #expect(adminGRPCBootstrapSource.contains("public convenience init("))
        #expect(adminGRPCBootstrapSource.contains("FirestoreGRPCTransportFactory.make("))
        #expect(!adminGRPCBootstrapSource.contains("ClientTransport"))
        #expect(!adminGRPCBootstrapSource.contains("transport: Transport"))
        #expect(transportFactorySource.contains("package static func make<Transport: ClientTransport>("))
        #expect(transportFactorySource.contains("transport: Transport"))
        #expect(adminSource.contains("referenceRuntime: any FirestoreReferenceRuntime"))
        #expect(adminSource.contains("collectionGroupRuntime: any FirestoreCollectionGroupRuntime"))
        #expect(adminSource.contains("batchWriteRuntime: any FirestoreBatchWriteRuntime"))
        #expect(adminSource.contains("pipelineRuntime: any FirestorePipelineRuntime"))
        #expect(transportFactorySource.contains("package let referenceRuntime: any FirestoreReferenceRuntime"))
        #expect(transportFactorySource.contains("package let collectionGroupRuntime: any FirestoreCollectionGroupRuntime"))
        #expect(transportFactorySource.contains("package let batchWriteRuntime: any FirestoreBatchWriteRuntime"))
        #expect(transportFactorySource.contains("package let pipelineRuntime: any FirestorePipelineRuntime"))
        #expect(adminGRPCBootstrapSource.contains("referenceRuntime: transportRuntime.referenceRuntime"))
        #expect(adminGRPCBootstrapSource.contains("collectionGroupRuntime: transportRuntime.collectionGroupRuntime"))
        #expect(adminGRPCBootstrapSource.contains("batchWriteRuntime: transportRuntime.batchWriteRuntime"))
        #expect(adminGRPCBootstrapSource.contains("pipelineRuntime: transportRuntime.pipelineRuntime"))
        #expect(!adminSource.contains("runtime: any FirestoreRuntime"))
        #expect(!adminSource.contains("let runtime: any FirestoreRuntime"))
        #expect(!transportFactorySource.contains("package let runtime: any FirestoreRuntime"))
        #expect(!adminGRPCBootstrapSource.contains("transportRuntime.runtime"))

        let forbiddenPublicTransportTokens = [
            "public convenience init<Transport",
            "public init<Transport",
            "public convenience init(projectId: String, transport:",
            "public init(projectId: String, transport:"
        ]
        for token in forbiddenPublicTransportTokens {
            #expect(!adminGRPCBootstrapSource.contains(token), "FirestoreAdmin transport injection should stay internal and must not expose \(token).")
            #expect(!transportFactorySource.contains(token), "FirestoreGRPCTransportFactory transport seam should stay package-only and must not expose \(token).")
        }

        for source in [adminSource, clientSource] {
            #expect(!source.contains("ClientTransport"))
            #expect(!source.contains("FirestoreGRPCRuntime"))
            #expect(!source.contains("transport:"))
        }
    }

    @Test("Runtime protocols remain internal implementation seams")
    func testRuntimeProtocolsRemainInternalImplementationSeams() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let apiRuntimeSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreRuntimeSupport/FirestoreRuntime.swift"),
            encoding: .utf8
        )
        let coreRuntimeSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/FirestoreRuntime.swift"),
            encoding: .utf8
        )
        let transactionRuntimeSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreRuntimeSupport/FirestoreTransactionRuntime.swift"),
            encoding: .utf8
        )
        let adminClientSourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdminClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminReferenceClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransactionClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminPipelineClient.swift",
            "Sources/FirestoreAdmin/FirestoreAdminLifecycleClient.swift"
        ]
        let adminClientSource = try adminClientSourcePaths
            .map { try String(contentsOf: rootURL.appending(path: $0), encoding: .utf8) }
            .joined(separator: "\n")
        let documentReferenceSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/DocumentReference.swift"),
            encoding: .utf8
        )
        let collectionReferenceSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/CollectionReference.swift"),
            encoding: .utf8
        )
        let collectionGroupSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/CollectionGroup.swift"),
            encoding: .utf8
        )
        let querySource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/Query.swift"),
            encoding: .utf8
        )

        #expect(apiRuntimeSource.contains("protocol FirestoreRuntime"))
        #expect(apiRuntimeSource.contains("protocol FirestoreBatchWriteRuntime"))
        #expect(apiRuntimeSource.contains("protocol FirestorePipelineRuntime"))
        #expect(coreRuntimeSource.contains("package protocol FirestoreDocumentRuntime"))
        #expect(coreRuntimeSource.contains("package protocol FirestoreCollectionRuntime"))
        #expect(coreRuntimeSource.contains("package protocol FirestoreQueryRuntime"))
        #expect(coreRuntimeSource.contains("package protocol FirestorePartitionQueryRuntime"))
        #expect(coreRuntimeSource.contains("package protocol FirestoreReferenceRuntime"))
        #expect(coreRuntimeSource.contains("package protocol FirestoreCollectionGroupRuntime"))
        #expect(transactionRuntimeSource.contains("protocol FirestoreTransactionRuntime"))
        #expect(!apiRuntimeSource.contains("public protocol FirestoreRuntime"))
        #expect(!apiRuntimeSource.contains("public protocol FirestoreBatchWriteRuntime"))
        #expect(!apiRuntimeSource.contains("public protocol FirestorePipelineRuntime"))
        #expect(!coreRuntimeSource.contains("public protocol FirestoreDocumentRuntime"))
        #expect(!coreRuntimeSource.contains("public protocol FirestoreCollectionRuntime"))
        #expect(!coreRuntimeSource.contains("public protocol FirestoreQueryRuntime"))
        #expect(!coreRuntimeSource.contains("public protocol FirestorePartitionQueryRuntime"))
        #expect(!apiRuntimeSource.contains("protocol FirestoreDocumentRuntime"))
        #expect(!apiRuntimeSource.contains("protocol FirestoreCollectionRuntime"))
        #expect(!apiRuntimeSource.contains("protocol FirestoreQueryRuntime"))
        #expect(!apiRuntimeSource.contains("protocol FirestorePartitionQueryRuntime"))
        #expect(!transactionRuntimeSource.contains("public protocol FirestoreTransactionRuntime"))
        #expect(adminClientSource.contains("public protocol FirestoreAdminClient"))
        #expect(adminClientSource.contains("public protocol FirestoreAdminReferenceClient"))
        #expect(adminClientSource.contains("public protocol FirestoreAdminWriteClient"))
        #expect(adminClientSource.contains("public protocol FirestoreAdminTransactionClient"))
        #expect(adminClientSource.contains("public protocol FirestoreAdminPipelineClient"))
        #expect(adminClientSource.contains("public protocol FirestoreAdminLifecycleClient"))
        #expect(adminClientSource.contains("FirestoreAdminReferenceClient,"))
        #expect(adminClientSource.contains("FirestoreAdminWriteClient,"))
        #expect(adminClientSource.contains("FirestoreAdminTransactionClient,"))
        #expect(adminClientSource.contains("FirestoreAdminPipelineClient,"))
        #expect(adminClientSource.contains("FirestoreAdminLifecycleClient"))
        let forbiddenAdminClientRuntimeTokens = [
            "any FirestoreRuntime",
            "any FirestoreReferenceRuntime",
            "any FirestoreCollectionGroupRuntime",
            "any FirestoreBatchWriteRuntime",
            "any FirestorePipelineRuntime",
            "any FirestoreTransactionRuntime",
            "FirestoreDocumentRuntime",
            "FirestoreCollectionRuntime",
            "FirestoreQueryRuntime",
            "FirestorePartitionQueryRuntime"
        ]
        for token in forbiddenAdminClientRuntimeTokens {
            #expect(!adminClientSource.contains(token))
        }
        #expect(documentReferenceSource.contains("any FirestoreReferenceRuntime"))
        #expect(collectionReferenceSource.contains("any FirestoreReferenceRuntime"))
        #expect(collectionGroupSource.contains("any FirestoreCollectionGroupRuntime"))
        #expect(querySource.contains("any FirestoreQueryRuntime"))
        for source in [documentReferenceSource, collectionReferenceSource, collectionGroupSource, querySource] {
            #expect(!source.contains("any FirestoreRuntime"))
        }
    }

    @Test("Reference query and snapshot models keep Codable helpers separate")
    func testReferenceQueryAndSnapshotModelsKeepCodableHelpersSeparate() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let modelSourcePaths = [
            "Sources/FirestoreCore/DocumentReference.swift",
            "Sources/FirestoreCore/CollectionReference.swift",
            "Sources/FirestoreCore/CollectionGroup.swift",
            "Sources/FirestoreCore/Query.swift",
            "Sources/FirestoreCore/DocumentSnapshot.swift",
            "Sources/FirestoreCore/QueryDocumentSnapshot.swift",
            "Sources/FirestoreCore/QuerySnapshot.swift"
        ]
        let codableSourcePaths = [
            "Sources/FirestoreCodable/Cadable/DocumentReference+Codable.swift",
            "Sources/FirestoreCodable/Cadable/CollectionReference+Codable.swift",
            "Sources/FirestoreCodable/Cadable/CollectionGroup+Codable.swift",
            "Sources/FirestoreCodable/Cadable/Query+Codable.swift",
            "Sources/FirestoreCodable/Cadable/Snapshot+Codable.swift"
        ]
        let adminModelSourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdminWriteBatch.swift",
            "Sources/FirestoreAdmin/FirestoreAdminBulkWriter.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransaction.swift"
        ]
        let adminCodableSourcePaths = [
            "Sources/FirestoreAdminCodable/FirestoreAdminWriteBatch+Codable.swift",
            "Sources/FirestoreAdminCodable/FirestoreAdminBulkWriter+Codable.swift",
            "Sources/FirestoreAdminCodable/FirestoreAdminTransaction+Codable.swift"
        ]

        for sourcePath in modelSourcePaths {
            let source = try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
            #expect(!source.contains("FirestoreEncoder"), "\(sourcePath) should keep FirestoreEncoder in Cadable extensions.")
            #expect(!source.contains("FirestoreDecoder"), "\(sourcePath) should keep FirestoreDecoder in Cadable extensions.")
            #expect(!source.contains("<T: Encodable>"), "\(sourcePath) should keep Encodable convenience in Cadable extensions.")
            #expect(!source.contains("<T: Decodable>"), "\(sourcePath) should keep Decodable convenience in Cadable extensions.")
        }

        for sourcePath in codableSourcePaths {
            let source = try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
            #expect(
                source.contains("FirestoreEncoder") || source.contains("FirestoreDecoder") || source.contains("Decodable"),
                "\(sourcePath) should own Firestore Codable convenience."
            )
        }

        for sourcePath in adminModelSourcePaths {
            let source = try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
            #expect(!source.contains("import FirestoreCodable"), "\(sourcePath) should keep Codable helpers in Admin Codable extensions.")
            #expect(!source.contains("FirestoreEncoder"), "\(sourcePath) should keep FirestoreEncoder in Admin Codable extensions.")
            #expect(!source.contains("FirestoreDecoder"), "\(sourcePath) should keep FirestoreDecoder in Admin Codable extensions.")
            #expect(!source.contains("<T: Encodable>"), "\(sourcePath) should keep Encodable convenience in Admin Codable extensions.")
            #expect(!source.contains("<T: Decodable>"), "\(sourcePath) should keep Decodable convenience in Admin Codable extensions.")
        }

        for sourcePath in adminCodableSourcePaths {
            let source = try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
            #expect(source.contains("import FirestoreAdmin"), "\(sourcePath) should extend Admin builders from the Admin Codable target.")
            #expect(source.contains("import FirestoreCodable"), "\(sourcePath) should own Admin Codable convenience.")
        }

        let packageSource = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let codableExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreCodableExports.swift"),
            encoding: .utf8
        )
        let adminCodableExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreAdminCodableExports.swift"),
            encoding: .utf8
        )
        #expect(packageSource.contains("name: \"FirestoreCodable\""))
        #expect(packageSource.contains("name: \"FirestoreAdminCodable\""))
        #expect(packageSource.contains("\"FirestoreCodable\""))
        #expect(codableExportSource.contains("@_exported import FirestoreCodable"))
        #expect(adminCodableExportSource.contains("@_exported import FirestoreAdminCodable"))

        let codableRootURL = rootURL.appending(path: "Sources/FirestoreCodable")
        let adminRootURL = rootURL.appending(path: "Sources/FirestoreAdmin")
        let adminCodableRootURL = rootURL.appending(path: "Sources/FirestoreAdminCodable")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: codableRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreCodable source directory should be readable.")
            return
        }
        let forbiddenCodableTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "import FirestoreRPC",
            "import FirestoreProtobuf",
            "import FirestoreGRPCStubs",
            "Google_Firestore_",
            "Google_Protobuf_",
            "SwiftProtobuf",
            "ClientTransport",
            "RPCError"
        ]
        var checkedFileCount = 0
        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenCodableTokens {
                #expect(!source.contains(token), "\(sourceURL.path()) should keep \(token) outside FirestoreCodable.")
            }
        }
        #expect(checkedFileCount > 0, "FirestoreCodable source files should be checked.")

        guard let adminEnumerator = fileManager.enumerator(
            at: adminRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreAdmin source directory should be readable.")
            return
        }
        var checkedAdminFileCount = 0
        for case let sourceURL as URL in adminEnumerator where sourceURL.pathExtension == "swift" {
            checkedAdminFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            #expect(!source.contains("import FirestoreCodable"), "\(sourceURL.path()) should keep Codable helpers in FirestoreAdminCodable.")
        }
        #expect(checkedAdminFileCount > 0, "FirestoreAdmin source files should be checked.")

        guard let adminCodableEnumerator = fileManager.enumerator(
            at: adminCodableRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreAdminCodable source directory should be readable.")
            return
        }
        var checkedAdminCodableFileCount = 0
        for case let sourceURL as URL in adminCodableEnumerator where sourceURL.pathExtension == "swift" {
            checkedAdminCodableFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenCodableTokens {
                #expect(!source.contains(token), "\(sourceURL.path()) should keep \(token) outside FirestoreAdminCodable.")
            }
        }
        #expect(checkedAdminCodableFileCount > 0, "FirestoreAdminCodable source files should be checked.")
    }

    @Test("Core model files do not depend on protobuf implementation types")
    func testCoreModelFilesDoNotDependOnProtobufImplementationTypes() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceRootURL = rootURL.appending(path: "Sources/FirestoreCore")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: sourceRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreCore source directory should be readable.")
            return
        }

        let forbiddenTokens = [
            "Google_Firestore_",
            "Google_Protobuf_",
            "SwiftProtobuf"
        ]
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            let path = sourceURL.path()
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(path) should keep \(token) inside RPC implementation files.")
            }
        }

        #expect(checkedFileCount > 0, "Core source files should be checked.")
    }

    @Test("Runtime configuration stays out of Core and transport implementation dependencies")
    func testRuntimeConfigurationStaysOutOfCoreAndTransportImplementationDependencies() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let packageManifest = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let runtimeConfigRootURL = rootURL.appending(path: "Sources/FirestoreRuntimeConfig")
        let coreRootURL = rootURL.appending(path: "Sources/FirestoreCore")
        let exportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreRuntimeConfigExports.swift"),
            encoding: .utf8
        )
        let fileManager = FileManager.default

        #expect(packageManifest.contains("name: \"FirestoreRuntimeConfig\""))
        #expect(packageManifest.contains("\"FirestoreRuntimeConfig\""))
        #expect(exportSource.contains("@_exported import FirestoreRuntimeConfig"))

        let runtimeConfigExpectedFiles = [
            "FirestoreSetting.swift",
            "FirestoreRetry.swift",
            "FirestoreAuthenticationMode.swift"
        ]
        for fileName in runtimeConfigExpectedFiles {
            #expect(
                fileManager.fileExists(atPath: runtimeConfigRootURL.appending(path: fileName).path()),
                "\(fileName) should live in FirestoreRuntimeConfig."
            )
            #expect(
                !fileManager.fileExists(atPath: coreRootURL.appending(path: fileName).path()),
                "\(fileName) should not live in FirestoreCore."
            )
        }

        guard let runtimeEnumerator = fileManager.enumerator(
            at: runtimeConfigRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreRuntimeConfig source directory should be readable.")
            return
        }
        let forbiddenRuntimeConfigTokens = [
            "import FirestoreAuth",
            "import FirestoreAuthCore",
            "import FirestoreGRPCTransport",
            "import FirestoreGRPCStubs",
            "import FirestoreProtobuf",
            "import FirestoreRPC",
            "import FirestorePipelineRPC",
            "import FirestorePipeline",
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "import SwiftProtobuf",
            "import Logging",
            "Google_Firestore_",
            "Google_Protobuf_",
            "ClientTransport",
            "RPCError",
            "PipelineCompiler",
            "QueryCompiler",
            "DocumentRequestCompiler",
            "WriteCompiler"
        ]
        var checkedRuntimeConfigFileCount = 0
        for case let sourceURL as URL in runtimeEnumerator where sourceURL.pathExtension == "swift" {
            checkedRuntimeConfigFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenRuntimeConfigTokens {
                #expect(!source.contains(token), "\(sourceURL.path()) should keep \(token) outside FirestoreRuntimeConfig.")
            }
        }
        #expect(checkedRuntimeConfigFileCount > 0, "FirestoreRuntimeConfig source files should be checked.")
    }

    @Test("RPC compiler and reducer files do not depend on gRPC transport types")
    func testRPCCompilerAndReducerFilesDoNotDependOnGRPCTransportTypes() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let rpcRootURL = rootURL.appending(path: "Sources/FirestoreRPC")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rpcRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreAPI RPC directory should be readable.")
            return
        }

        let forbiddenTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "ClientTransport",
            "StreamingClientRequest",
            "StreamingClientResponse",
            "RPCError",
            "FirestoreError.fromRPCError"
        ]
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourceURL.path()) should keep \(token) in the gRPC transport layer.")
            }
        }

        #expect(checkedFileCount > 0, "RPC source files should be checked.")
    }

    @Test("Native query APIs do not contain Mongo-compatible geospatial constructs")
    func testNativeQueryAPIsDoNotContainMongoCompatibleGeospatialConstructs() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreCore/Query.swift",
            "Sources/FirestoreCore/QueryPredicate.swift",
            "Sources/FirestoreGeoQuery/FirestoreGeoQuery.swift",
            "Sources/FirestorePipeline/FirestorePipeline.swift",
            "Sources/FirestorePipeline/PipelineValue.swift",
            "Sources/FirestorePipeline/PipelineValue+CoreExpressions.swift",
            "Sources/FirestorePipeline/PipelineValue+NumericComparison.swift",
            "Sources/FirestorePipeline/PipelineValue+Logic.swift",
            "Sources/FirestorePipeline/PipelineValue+Collections.swift",
            "Sources/FirestorePipeline/PipelineValue+Strings.swift",
            "Sources/FirestorePipeline/PipelineValue+Timestamps.swift",
            "Sources/FirestorePipeline/PipelineValue+ReferenceVectorAggregation.swift"
        ]
        let forbiddenTokens = [
            "$near",
            "2dsphere",
            "geoNear",
            "geoWithin",
            "geoIntersects",
            "Mongo",
            "BSON"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should keep \(token) out of Native Firestore query APIs.")
            }
        }

        let packageSource = try String(
            contentsOf: rootURL.appending(path: "Package.swift"),
            encoding: .utf8
        )
        let geoQueryExportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAPI/FirestoreGeoQueryExports.swift"),
            encoding: .utf8
        )
        #expect(packageSource.contains("name: \"FirestoreGeoQuery\""))
        #expect(packageSource.contains("\"FirestoreGeoQuery\""))
        #expect(geoQueryExportSource.contains("@_exported import FirestoreGeoQuery"))

        let geoQueryRootURL = rootURL.appending(path: "Sources/FirestoreGeoQuery")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: geoQueryRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreGeoQuery source directory should be readable.")
            return
        }
        let forbiddenGeoQueryTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "import GRPCNIOTransport",
            "import FirestoreRPC",
            "import FirestoreProtobuf",
            "import FirestoreGRPCStubs",
            "Google_Firestore_",
            "Google_Protobuf_",
            "SwiftProtobuf",
            "ClientTransport",
            "RPCError",
            "$near",
            "2dsphere",
            "geoNear",
            "geoWithin",
            "geoIntersects",
            "Mongo",
            "BSON"
        ]
        var checkedFileCount = 0
        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenGeoQueryTokens {
                #expect(!source.contains(token), "\(sourceURL.path()) should keep \(token) outside Native Firestore GeoQuery.")
            }
        }
        #expect(checkedFileCount > 0, "FirestoreGeoQuery source files should be checked.")
    }

    @Test("Server-side Admin surface does not expose client-only SDK APIs")
    func testServerSideAdminSurfaceDoesNotExposeClientOnlySDKAPIs() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdmin.swift",
            "Sources/FirestoreCore/DocumentReference.swift",
            "Sources/FirestoreCore/CollectionReference.swift",
            "Sources/FirestoreCore/CollectionGroup.swift",
            "Sources/FirestoreCore/Query.swift"
        ]
        let forbiddenTokens = [
            "func clearPersistence",
            "func enableNetwork",
            "func disableNetwork",
            "func waitForPendingWrites",
            "ListenerRegistration",
            "func addSnapshotsInSyncListener",
            "snapshotsInSync",
            "PersistentCache",
            "MemoryCache",
            "LocalCache",
            "cacheSettings",
            "func terminate"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should not expose client-only API \(token).")
            }
        }
    }

    @Test("QueryPredicate remains internal RPC planning state")
    func testQueryPredicateRemainsInternalRPCPlanningState() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let queryPredicateSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/QueryPredicate.swift"),
            encoding: .utf8
        )
        let querySource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/Query.swift"),
            encoding: .utf8
        )
        let collectionSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/CollectionReference+Query.swift"),
            encoding: .utf8
        )
        let collectionGroupSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/CollectionGroup+Query.swift"),
            encoding: .utf8
        )

        #expect(queryPredicateSource.contains("package enum QueryPredicate"))
        #expect(!queryPredicateSource.contains("public enum QueryPredicate"))

        let forbiddenQueryPredicateTokens = [
            "public enum QueryPredicate",
            "public func == (field: String",
            "public func != (field: String",
            "public func < (field: String",
            "public func <= (field: String",
            "public func > (field: String",
            "public func >= (field: String",
            "public func ~= "
        ]
        for token in forbiddenQueryPredicateTokens {
            #expect(!queryPredicateSource.contains(token), "QueryPredicate.swift should not expose \(token).")
        }

        let forbiddenQuerySurfaceTokens = [
            "public func or(_ filters: [QueryPredicate])",
            "public func and(_ filters: [QueryPredicate])"
        ]
        for source in [querySource, collectionSource, collectionGroupSource] {
            for token in forbiddenQuerySurfaceTokens {
                #expect(!source.contains(token), "Public query surface should use Filter instead of \(token).")
            }
        }
    }

    @Test("Query sources use FirestoreQuerySource defaults")
    func testQuerySourcesUseFirestoreQuerySourceDefaults() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let sharedSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreCore/FirestoreQuerySource.swift"),
            encoding: .utf8
        )
        let querySources = [
            "Sources/FirestoreCore/Query.swift": try String(
                contentsOf: rootURL.appending(path: "Sources/FirestoreCore/Query.swift"),
                encoding: .utf8
            ),
            "Sources/FirestoreCore/CollectionReference+Query.swift": try String(
                contentsOf: rootURL.appending(path: "Sources/FirestoreCore/CollectionReference+Query.swift"),
                encoding: .utf8
            ),
            "Sources/FirestoreCore/CollectionGroup+Query.swift": try String(
                contentsOf: rootURL.appending(path: "Sources/FirestoreCore/CollectionGroup+Query.swift"),
                encoding: .utf8
            )
        ]

        let requiredSharedTokens = [
            "public extension FirestoreQuerySource",
            "func whereField(_ field: String, isEqualTo value: Any) -> Query",
            "func start(at values: [Any]) -> Query",
            "func start(after values: [Any]) -> Query",
            "func end(at values: [Any]) -> Query",
            "func end(before values: [Any]) -> Query",
            "func start(atDocument snapshot: DocumentSnapshot) throws -> Query",
            "func start(afterDocument snapshot: DocumentSnapshot) throws -> Query",
            "func end(atDocument snapshot: DocumentSnapshot) throws -> Query",
            "func end(beforeDocument snapshot: DocumentSnapshot) throws -> Query",
            "func start(atDocument snapshot: QueryDocumentSnapshot) throws -> Query",
            "func start(afterDocument snapshot: QueryDocumentSnapshot) throws -> Query",
            "func end(atDocument snapshot: QueryDocumentSnapshot) throws -> Query",
            "func end(beforeDocument snapshot: QueryDocumentSnapshot) throws -> Query",
            "func or(_ filters: [Filter]) -> Query",
            "func and(_ filters: [Filter]) -> Query"
        ]
        for token in requiredSharedTokens {
            #expect(sharedSource.contains(token), "FirestoreQuerySource.swift should own shared query API token \(token).")
        }

        let forbiddenSharedTokens = [
            "func `where`(field:",
            "func `where`(isEqualTo",
            "func `where`(isNotEqualTo",
            "func `where`(isLessThan",
            "func `where`(isLessThanOrEqualTo",
            "func `where`(isGreaterThan",
            "func `where`(isGreaterThanOrEqualTo",
            "func `where`(arrayContains",
            "func `where`(arrayContainsAny",
            "func `where`(in ",
            "func `where`(notIn "
        ]
        for token in forbiddenSharedTokens {
            #expect(!sharedSource.contains(token), "FirestoreQuerySource.swift should keep the public query surface on whereField and Filter, not \(token).")
        }

        let forbiddenQuerySourceTokens = [
            "public func `where`(field:",
            "public func whereField",
            "public func or(_ filters: [Filter])",
            "public func and(_ filters: [Filter])",
            "arrayContains",
            "isEqualToDocumentID",
            "isNotEqualToDocumentID"
        ]
        for (path, source) in querySources {
            for token in forbiddenQuerySourceTokens {
                #expect(!source.contains(token), "\(path) should delegate shared query API token \(token) to FirestoreQuerySource defaults.")
            }
        }
    }

    @Test("Public error model does not depend on gRPC types")
    func testPublicErrorModelDoesNotDependOnGRPCTypes() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePath = "Sources/FirestoreCore/FirestoreError.swift"
        let forbiddenTokens = [
            "import GRPCCore",
            "RPCError"
        ]

        let sourceURL = rootURL.appending(path: sourcePath)
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        for token in forbiddenTokens {
            #expect(!source.contains(token), "\(sourcePath) should not contain \(token).")
        }
    }

    @Test("Batch and transaction core types do not depend on transport generics")
    func testBatchAndTransactionCoreTypesDoNotDependOnTransportGenerics() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreCore/WriteData.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteBuffer.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteBatch.swift",
            "Sources/FirestoreCore/TransactionOptions.swift",
            "Sources/FirestoreAdmin/TransactionError.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransaction.swift"
        ]
        let forbiddenTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "ClientTransport",
            "Firestore<Transport>",
            "FirestoreGRPCRuntime<Transport>",
            "WriteBatch<Transport>",
            "Transaction<Transport>"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should not contain \(token).")
            }
        }
    }

    @Test("Admin write staging remains centralized")
    func testAdminWriteStagingRemainsCentralized() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let bufferSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreAdmin/FirestoreAdminWriteBuffer.swift"),
            encoding: .utf8
        )
        let publicWriteSources = [
            "Sources/FirestoreAdmin/FirestoreAdminWriteBatch.swift",
            "Sources/FirestoreAdmin/FirestoreAdminBulkWriter.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransaction.swift"
        ]

        #expect(bufferSource.contains("final class FirestoreAdminWriteBuffer"))
        #expect(bufferSource.contains("private var writes: [WriteData]"))
        #expect(bufferSource.contains("private var validationError: FirestoreError?"))
        #expect(bufferSource.contains("func validateNoDuplicateDocuments() throws"))
        #expect(bufferSource.contains("func validateNoPendingWrites() throws"))

        for sourcePath in publicWriteSources {
            let source = try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
            #expect(source.contains("FirestoreAdminWriteBuffer"), "\(sourcePath) should use FirestoreAdminWriteBuffer.")
            #expect(!source.contains("private var writes: [WriteData]"), "\(sourcePath) should not own write storage.")
            #expect(!source.contains("private var validationError"), "\(sourcePath) should not own write validation state.")
        }
    }

    @Test("Runtime delegation layer does not construct gRPC requests")
    func testRuntimeDelegationLayerDoesNotConstructGRPCRequests() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreCore/FirestoreRuntime.swift",
            "Sources/FirestoreRuntimeSupport/FirestoreRuntime.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Runtime.swift"
        ]
        let forbiddenTokens = [
            "import GRPCCore",
            "import GRPCProtobuf",
            "Metadata",
            "ClientRequest",
            "StreamingClientRequest",
            "ProtobufSerializer",
            "authorizedMetadata"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should not contain \(token).")
            }
        }
    }

    @Test("Hand-written gRPC calls use generated client convenience methods")
    func testHandWrittenGRPCCallsUseGeneratedClientConvenienceMethods() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let grpcURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: grpcURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("gRPC source directory should be readable.")
            return
        }

        let forbiddenTokens = [
            "ProtobufSerializer",
            "ProtobufDeserializer",
            "serializer:",
            "deserializer:",
            "maxDuration: 30.0",
            "performing RPC calls"
        ]
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourceURL.path) should use generated client convenience methods instead of \(token).")
            }
        }

        #expect(checkedFileCount > 0, "Hand-written gRPC source files should be checked.")
    }

    @Test("Generated Firestore RPCs have explicit boundary decisions")
    func testGeneratedFirestoreRPCsHaveExplicitBoundaryDecisions() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let generatedSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCStubs/Proto/google/firestore/v1/firestore.grpc.swift"),
            encoding: .utf8
        )
        let auditDocument = try String(
            contentsOf: rootURL.appending(path: "docs/FirestoreRPCAudit.md"),
            encoding: .utf8
        )
        let compatibilityDocument = try String(
            contentsOf: rootURL.appending(path: "docs/FirestoreAdminCompatibility.md"),
            encoding: .utf8
        )

        let expectedRPCs = [
            "BatchGetDocuments",
            "BatchWrite",
            "BeginTransaction",
            "Commit",
            "CreateDocument",
            "DeleteDocument",
            "ExecutePipeline",
            "GetDocument",
            "ListCollectionIds",
            "ListDocuments",
            "Listen",
            "PartitionQuery",
            "Rollback",
            "RunAggregationQuery",
            "RunQuery",
            "UpdateDocument",
            "Write"
        ]
        let generatedRPCs = Set(generatedSource
            .split(separator: "\n")
            .compactMap { line -> String? in
                let marker = "method: \""
                guard let markerRange = line.range(of: marker) else {
                    return nil
                }
                let suffix = line[markerRange.upperBound...]
                guard let endIndex = suffix.firstIndex(of: "\"") else {
                    return nil
                }
                return String(suffix[..<endIndex])
            })

        #expect(generatedRPCs.sorted() == expectedRPCs)

        for rpc in expectedRPCs {
            #expect(
                auditDocument.contains("`\(rpc)`"),
                "Firestore RPC audit should explicitly record the boundary decision for \(rpc)."
            )
        }

        let lowLevelWriteRPCs = [
            "CreateDocument",
            "UpdateDocument",
            "DeleteDocument",
            "Write"
        ]
        #expect(auditDocument.contains("Low-level Write RPC Boundary"))
        #expect(compatibilityDocument.contains("Low-level Firestore write RPCs are not public API"))
        for rpc in lowLevelWriteRPCs {
            #expect(
                compatibilityDocument.contains("`\(rpc)`"),
                "Compatibility decision record should explicitly reject public exposure of \(rpc)."
            )
        }
    }

    @Test("Finite RPC request bodies are built by RPC compilers")
    func testFiniteRPCRequestBodiesAreBuiltByRPCCompilers() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        #expect(!FileManager.default.fileExists(
            atPath: rootURL.appending(path: "Sources/FirestoreGRPCTransport/Firestore+gRPC.swift").path()
        ))
        let sourcePaths = [
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Read.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Aggregation.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Pipeline.swift"
        ]
        let forbiddenRequestConstructors = [
            "Google_Firestore_V1_GetDocumentRequest()",
            "Google_Firestore_V1_BatchGetDocumentsRequest()",
            "Google_Firestore_V1_BeginTransactionRequest()",
            "Google_Firestore_V1_RollbackRequest()",
            "Google_Firestore_V1_ListDocumentsRequest()",
            "Google_Firestore_V1_ListCollectionIdsRequest()",
            "Google_Firestore_V1_BatchWriteRequest()",
            "Google_Firestore_V1_ExecutePipelineRequest()",
            "Google_Firestore_V1_CreateDocumentRequest()",
            "Google_Firestore_V1_UpdateDocumentRequest()",
            "Google_Firestore_V1_DeleteDocumentRequest()",
            "Google_Firestore_V1_WriteRequest()"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenRequestConstructors {
                #expect(!source.contains(token), "\(sourcePath) should delegate \(token) construction to an RPC compiler.")
            }
        }

        let documentSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift"),
            encoding: .utf8
        )
        let collectionSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift"),
            encoding: .utf8
        )
        let readSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Read.swift"),
            encoding: .utf8
        )
        let transactionSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift"),
            encoding: .utf8
        )
        let pipelineSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Pipeline.swift"),
            encoding: .utf8
        )
        let batchWriteSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift"),
            encoding: .utf8
        )
        #expect(documentSource.contains("DocumentRequestCompiler"))
        #expect(collectionSource.contains("DocumentRequestCompiler"))
        #expect(readSource.contains("DocumentRequestCompiler"))
        #expect(transactionSource.contains("TransactionRequestCompiler"))
        #expect(pipelineSource.contains("PipelineCompiler"))
        #expect(transactionSource.contains("WriteCompiler"))
        #expect(batchWriteSource.contains("BatchWriteCompiler"))
    }

    @Test("gRPC request wrappers stay in dedicated transport files")
    func testGRPCRequestWrappersStayInDedicatedTransportFiles() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let transportRootURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: transportRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("FirestoreGRPCTransport source directory should be readable.")
            return
        }

        let finiteRequestOwner = "FirestoreGRPCRuntime+FiniteRequest.swift"
        let streamingRequestOwner = "FirestoreListenStreamExecutor.swift"
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let fileName = sourceURL.lastPathComponent
            let containsFiniteClientRequest = source.range(
                of: #"(^|[^A-Za-z])ClientRequest[<(]"#,
                options: .regularExpression
            ) != nil
            let containsStreamingClientRequest = source.range(
                of: #"StreamingClientRequest[<(]"#,
                options: .regularExpression
            ) != nil

            if fileName == finiteRequestOwner {
                #expect(containsFiniteClientRequest, "\(finiteRequestOwner) should own finite ClientRequest wrappers.")
            } else {
                #expect(!containsFiniteClientRequest, "\(sourceURL.path()) should not construct finite ClientRequest wrappers.")
            }

            if fileName == streamingRequestOwner {
                #expect(containsStreamingClientRequest, "\(streamingRequestOwner) should own streaming ClientRequest wrappers.")
            } else {
                #expect(!containsStreamingClientRequest, "\(sourceURL.path()) should not construct streaming ClientRequest wrappers.")
            }
        }

        #expect(checkedFileCount > 0, "FirestoreGRPCTransport source files should be checked.")
    }

    @Test("Generated gRPC client calls stay in transport operation wrappers")
    func testGeneratedGRPCClientCallsStayInTransportOperationWrappers() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceRootURL = rootURL.appending(path: "Sources")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: sourceRootURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("Sources directory should be readable.")
            return
        }

        let operationWrapperFiles: Set<String> = [
            "FirestoreGRPCRuntime+Aggregation.swift",
            "FirestoreGRPCRuntime+BatchWrite.swift",
            "FirestoreGRPCRuntime+CollectionOperations.swift",
            "FirestoreGRPCRuntime+DocumentOperations.swift",
            "FirestoreGRPCRuntime+Listen.swift",
            "FirestoreGRPCRuntime+Pipeline.swift",
            "FirestoreGRPCRuntime+QueryOperations.swift",
            "FirestoreGRPCRuntime+Read.swift",
            "FirestoreGRPCRuntime+Transaction.swift"
        ]
        let generatedClientCallPattern = #"client\.(getDocument|listDocuments|updateDocument|deleteDocument|batchGetDocuments|beginTransaction|commit|rollback|runQuery|executePipeline|runAggregationQuery|partitionQuery|write|listen|listCollectionIds|batchWrite|createDocument)\("#
        let forbiddenWriteClientCallPattern = #"client\.(createDocument|updateDocument|deleteDocument|write)\("#
        var checkedFileCount = 0

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            let path = sourceURL.path()
            guard !path.contains("/Proto/") else {
                continue
            }
            checkedFileCount += 1
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let fileName = sourceURL.lastPathComponent
            let containsGeneratedClientCall = source.range(
                of: generatedClientCallPattern,
                options: .regularExpression
            ) != nil
            let containsForbiddenWriteClientCall = source.range(
                of: forbiddenWriteClientCallPattern,
                options: .regularExpression
            ) != nil

            if !operationWrapperFiles.contains(fileName) {
                #expect(!containsGeneratedClientCall, "\(path) should not call generated Firestore clients directly.")
            }
            #expect(!containsForbiddenWriteClientCall, "\(path) should not use low-level write generated client calls.")
        }

        #expect(checkedFileCount > 0, "Hand-written source files should be checked.")
    }

    @Test("Hand-written gRPC write calls stay on Commit and BatchWrite")
    func testHandWrittenGRPCWriteCallsStayOnCommitAndBatchWrite() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let grpcSourcePaths = [
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift"
        ]
        let forbiddenClientCalls = [
            "client.createDocument(",
            "client.updateDocument(",
            "client.deleteDocument(",
            "client.write("
        ]

        for sourcePath in grpcSourcePaths {
            let source = try String(
                contentsOf: rootURL.appending(path: sourcePath),
                encoding: .utf8
            )
            for token in forbiddenClientCalls {
                #expect(!source.contains(token), "\(sourcePath) should use Commit or BatchWrite instead of \(token).")
            }
        }

        let documentSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift"),
            encoding: .utf8
        )
        #expect(documentSource.contains("executeCommit("))

        let transactionSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift"),
            encoding: .utf8
        )
        let batchWriteSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift"),
            encoding: .utf8
        )
        #expect(transactionSource.contains("client.commit("))
        #expect(batchWriteSource.contains("client.batchWrite("))
    }

    @Test("Finite RPC responses are mapped by RPC response mappers")
    func testFiniteRPCResponsesAreMappedByRPCResponseMappers() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Read.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Aggregation.swift"
        ]
        let forbiddenTokens = [
            "FirestoreDocumentDataDecoder()",
            "QueryDocumentSnapshot(",
            "QuerySnapshot(documents:",
            "throws -> [String: Google_Firestore_V1_Value]",
            "return DocumentSnapshot("
        ]

        for sourcePath in sourcePaths {
            let source = try String(
                contentsOf: rootURL.appending(path: sourcePath),
                encoding: .utf8
            )
            #expect(source.contains("ReadResponseMapper"), "\(sourcePath) should delegate response mapping to ReadResponseMapper.")
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourcePath) should not directly map finite read responses with \(token).")
            }
        }

        let collectionTransportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift"),
            encoding: .utf8
        )
        let aggregationTransportSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Aggregation.swift"),
            encoding: .utf8
        )
        #expect(!collectionTransportSource.contains("executeAggregate("))
        #expect(!collectionTransportSource.contains("executeExplainAggregation("))
        #expect(aggregationTransportSource.contains("executeAggregate("))
        #expect(aggregationTransportSource.contains("executeExplainAggregation("))

        let mapperSourcePaths = [
            "Sources/FirestoreRPC/ReadResponseMapper.swift",
            "Sources/FirestoreRPC/ReadResponseMapper+Documents.swift",
            "Sources/FirestoreRPC/ReadResponseMapper+Aggregation.swift",
            "Sources/FirestoreRPC/ReadResponseMapper+Explain.swift"
        ]
        let mapperSource = try mapperSourcePaths.map { sourcePath in
            try String(contentsOf: rootURL.appending(path: sourcePath), encoding: .utf8)
        }.joined(separator: "\n")
        #expect(mapperSource.contains("DocumentSnapshot("))
        #expect(mapperSource.contains("QueryDocumentSnapshot("))
        #expect(mapperSource.contains("QuerySnapshot(documents:"))
        #expect(mapperSource.contains("makeAggregateFields"))
        #expect(mapperSource.contains("makeAggregateSnapshot"))
        #expect(mapperSource.contains("CollectionReference("))

        let pipelineMapperSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestorePipelineRPC/PipelineResponseMapper.swift"),
            encoding: .utf8
        )
        #expect(pipelineMapperSource.contains("makeSnapshot"))
        #expect(pipelineMapperSource.contains("FirestoreDocumentDataDecoder"))
    }

    @Test("Query predicate protobuf filters stay outside gRPC transport")
    func testQueryPredicateProtobufFiltersStayOutsideGRPCTransport() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let obsoleteURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport/QueryPredicate+gRPC.swift")
        #expect(!FileManager.default.fileExists(atPath: obsoleteURL.path()))

        let grpcURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: grpcURL,
            includingPropertiesForKeys: nil
        ) else {
            Issue.record("gRPC source directory should be readable.")
            return
        }

        let forbiddenTokens = [
            "extension QueryPredicate",
            "makeFieldFilter",
            "makeUnaryFilter",
            "makeDocumentReferencePath"
        ]

        for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            for token in forbiddenTokens {
                #expect(!source.contains(token), "\(sourceURL.path) should keep predicate filter compilation in RPC.")
            }
        }

        let compilerSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreRPC/QueryPredicateFilterCompiler.swift"),
            encoding: .utf8
        )
        let queryCompilerSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreRPC/QueryCompiler.swift"),
            encoding: .utf8
        )
        #expect(compilerSource.contains("struct QueryPredicateFilterCompiler"))
        #expect(compilerSource.contains("StructuredQuery.Filter"))
        #expect(queryCompilerSource.contains("QueryPredicateFilterCompiler"))
    }

    @Test("Listen transport wrapper refreshes authorization metadata")
    func testListenTransportWrapperRefreshesAuthorizationMetadata() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+QueryOperations.swift"
        ]

        for sourcePath in sourcePaths {
            let sourceURL = rootURL.appending(path: sourcePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            #expect(
                source.contains("try await self.listen(target: target)"),
                "\(sourcePath) should delegate Listen stream opening to the Listen transport wrapper."
            )
            #expect(
                !source.contains("authorizedMetadata()"),
                "\(sourcePath) should not construct Listen authorization metadata directly."
            )
        }

        let listenSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Listen.swift"),
            encoding: .utf8
        )
        #expect(listenSource.contains("FirestoreListenStreamExecutor"))
        #expect(listenSource.contains("metadata: try await authorizedMetadata()"))
        #expect(!listenSource.contains("ListenRequestStreamController"))
        #expect(!listenSource.contains("StreamingClientRequest"))
        #expect(!listenSource.contains("continuation.onTermination"))
        #expect(!listenSource.contains("closeTarget()"))
        #expect(!listenSource.contains("FirestoreListenRequestChannel"))
        #expect(!listenSource.contains("pendingRequests"))
        #expect(!listenSource.contains("makeAddTargetRequest"))
        #expect(!listenSource.contains("makeRemoveTargetRequest"))

        let listenExecutorURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreListenStreamExecutor.swift")
        let listenExecutorSource = try String(contentsOf: listenExecutorURL, encoding: .utf8)
        #expect(listenExecutorSource.contains("ListenRequestStreamController"))
        #expect(listenExecutorSource.contains("StreamingClientRequest"))
        #expect(listenExecutorSource.contains("continuation.onTermination"))
        #expect(listenExecutorSource.contains("closeTarget()"))
        #expect(listenExecutorSource.contains("FirestoreError.fromRPCError"))

        let coordinatorSourceURL = rootURL.appending(path: "Sources/FirestoreRPC/Listen/ListenStreamCoordinator.swift")
        let coordinatorSource = try String(contentsOf: coordinatorSourceURL, encoding: .utf8)
        #expect(coordinatorSource.contains("task.cancel()"))
        #expect(!coordinatorSource.contains("import GRPCCore"))
        #expect(!coordinatorSource.contains("RPCError"))
        #expect(!coordinatorSource.contains("FirestoreError.fromRPCError"))

        let requestStreamControllerURL = rootURL.appending(path: "Sources/FirestoreRPC/Listen/ListenRequestStreamController.swift")
        let requestStreamControllerSource = try String(contentsOf: requestStreamControllerURL, encoding: .utf8)
        #expect(requestStreamControllerSource.contains("makeAddTargetRequest"))
        #expect(requestStreamControllerSource.contains("makeRemoveTargetRequest"))
        #expect(requestStreamControllerSource.contains("pendingRequests"))
        #expect(requestStreamControllerSource.contains("finish()"))
    }

    @Test("Finite RPCs use timeout call options and Listen remains long-lived")
    func testFiniteRPCsUseTimeoutCallOptionsAndListenRemainsLongLived() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let executionSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Execution.swift"),
            encoding: .utf8
        )
        let readSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Read.swift"),
            encoding: .utf8
        )
        let finiteRequestSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+FiniteRequest.swift"),
            encoding: .utf8
        )
        let authorizationSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Authorization.swift"),
            encoding: .utf8
        )
        let listenSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Listen.swift"),
            encoding: .utf8
        )

        #expect(executionSource.contains("options.timeout = settings.timeout"))
        #expect(executionSource.contains("retryMaxDuration"))
        #expect(readSource.contains("options: self.callOptions"))
        #expect(readSource.contains("executeFiniteRPC(message:"))
        #expect(finiteRequestSource.contains("ClientRequest("))
        #expect(finiteRequestSource.contains("metadata: try await authorizedMetadata()"))
        #expect(finiteRequestSource.contains("executeFiniteRPC<Message: Sendable, Output: Sendable>"))
        #expect(finiteRequestSource.contains("executeFiniteRPCWithoutAutomaticRetry<Message: Sendable, Output: Sendable>"))
        #expect(finiteRequestSource.contains("finiteRPCExecutor.executeWithRetry"))
        #expect(finiteRequestSource.contains("let request = try await self.makeFiniteRPCRequest(message: message)"))
        #expect(authorizationSource.contains("internal func authorizedMetadata() async throws -> Metadata"))
        #expect(!executionSource.contains("maxDuration: 30.0"))
        #expect(!listenSource.contains("options: self.callOptions"), "Listen should not use finite RPC timeout call options.")
    }

    @Test("Commit retry and ListCollectionIds pagination policies are explicit")
    func testCommitRetryAndListCollectionIDsPaginationPoliciesAreExplicit() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let transactionSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift"),
            encoding: .utf8
        )
        let batchWriteSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift"),
            encoding: .utf8
        )
        guard let commitStart = transactionSource.range(of: "internal func executeCommit"),
              let rollbackStart = transactionSource.range(of: "internal func rollbackTransaction")
        else {
            Issue.record("FirestoreGRPCRuntime+Transaction.swift should contain executeCommit and rollbackTransaction functions.")
            return
        }
        let commitSource = String(transactionSource[commitStart.lowerBound..<rollbackStart.lowerBound])
        #expect(commitSource.contains("client.commit("))
        #expect(commitSource.contains("executeFiniteRPCWithoutAutomaticRetry"))
        #expect(!commitSource.contains("executeWithRetry"), "Commit should not use automatic retry.")
        #expect(batchWriteSource.contains("client.batchWrite("))
        #expect(batchWriteSource.contains("executeFiniteRPC(message:"))
        #expect(batchWriteSource.contains("BatchWriteResponseMapper"))

        let executorSourceURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreRPCExecutor.swift")
        let executorSource = try String(contentsOf: executorSourceURL, encoding: .utf8)
        let retryableOperationSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreRetryableOperation.swift"),
            encoding: .utf8
        )
        #expect(executorSource.contains("executeWithRetry"))
        #expect(executorSource.contains("executeWithoutAutomaticRetry"))
        #expect(executorSource.contains("FirestoreRetryHandler"))
        #expect(executorSource.contains("FirestoreRetryableOperation"))
        #expect(retryableOperationSource.contains("FirestoreError.fromRPCError"))

        let grpcRuntimeSourcePaths = [
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Execution.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Read.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Aggregation.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Pipeline.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift",
            "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift"
        ]
        for sourcePath in grpcRuntimeSourcePaths {
            let source = try String(
                contentsOf: rootURL.appending(path: sourcePath),
                encoding: .utf8
            )
            #expect(!source.contains("FirestoreRetryHandler("), "\(sourcePath) should use FirestoreRPCExecutor for finite RPC retry policy.")
            #expect(!source.contains("ClientRequest<"), "\(sourcePath) should use makeFiniteRPCRequest for finite RPC request construction.")
            #expect(!source.contains("finiteRPCExecutor."), "\(sourcePath) should let FirestoreGRPCRuntime+FiniteRequest own finite RPC retry execution.")
        }

        let documentSourceURL = rootURL.appending(path: "Sources/FirestoreCore/DocumentReference.swift")
        let documentSource = try String(contentsOf: documentSourceURL, encoding: .utf8)
        #expect(documentSource.contains("public func listCollections() async throws -> [CollectionReference]"))
        #expect(documentSource.contains("listCollections(in: self)"))

        let collectionSourceURL = rootURL.appending(path: "Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift")
        let collectionSource = try String(contentsOf: collectionSourceURL, encoding: .utf8)
        #expect(collectionSource.contains("executeListCollections(in reference: DocumentReference)"))
        #expect(collectionSource.contains("executeListDocuments("))
        #expect(collectionSource.contains("makeListDocumentsRequest"))
        #expect(collectionSource.contains("makeListCollectionIdsRequest"))
        #expect(collectionSource.contains("documents.append(contentsOf: response.documents)"))
        #expect(collectionSource.contains("collectionIDs.append(contentsOf: response.collectionIds)"))
        #expect(collectionSource.contains("pageToken = response.nextPageToken"))
        #expect(collectionSource.contains("while !pageToken.isEmpty"))
    }

    @Test("Obsolete client-shaped entry points and legacy batch are removed")
    func testObsoleteClientShapedEntryPointsAndLegacyBatchAreRemoved() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let obsoletePaths = [
            "Sources/FirestoreAPI/Firestore.swift",
            "Sources/FirestoreAPI/Firestore+Transaction.swift",
            "Sources/FirestoreAPI/Transaction.swift",
            "Sources/FirestoreAPI/WriteBatch.swift",
            "Sources/FirestoreAPI/ExponentialBackoff.swift",
            "Sources/FirestoreAPI/Query+KeyedEncodingContainer.swift",
            "Sources/FirestoreGRPCTransport/DocumentReference+gRPC.swift",
            "Sources/FirestoreGRPCTransport/CollectionReference+gRPC.swift",
            "Sources/FirestoreGRPCTransport/Query+gRPC.swift"
        ]

        for obsoletePath in obsoletePaths {
            let sourceURL = rootURL.appending(path: obsoletePath)
            #expect(!FileManager.default.fileExists(atPath: sourceURL.path()), "\(obsoletePath) should not exist.")
        }

        let transactionBackoffSource = try String(
            contentsOf: rootURL.appending(path: "Sources/FirestoreRuntimeSupport/FirestoreTransactionBackoff.swift"),
            encoding: .utf8
        )
        #expect(transactionBackoffSource.contains("package final class FirestoreTransactionBackoff"))
    }

    @Test("Generated protobuf and gRPC sources are internal implementation details")
    func testGeneratedProtoSourcesDoNotExposePublicDeclarations() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let protoURLs = [
            rootURL.appending(path: "Sources/FirestoreProtobuf/Proto"),
            rootURL.appending(path: "Sources/FirestoreGRPCStubs/Proto")
        ]
        let fileManager = FileManager.default

        let forbiddenDeclarationPrefixes = [
            "\npublic struct ",
            "\npublic enum ",
            "\npublic class ",
            "\npublic protocol ",
            "\npublic typealias ",
            "\npublic extension ",
            "\npublic var ",
            "\npublic let ",
            "\npublic func ",
            "\npublic init"
        ]
        let forbiddenGeneratedExtensions = [
            "extension GRPCCore.ServiceDescriptor"
        ]
        var checkedFileCount = 0

        for protoURL in protoURLs {
            guard let enumerator = fileManager.enumerator(
                at: protoURL,
                includingPropertiesForKeys: nil
            ) else {
                Issue.record("Generated proto directory should be readable at \(protoURL.path()).")
                continue
            }

            for case let sourceURL as URL in enumerator where sourceURL.pathExtension == "swift" {
                checkedFileCount += 1
                let source = try String(contentsOf: sourceURL, encoding: .utf8)
                for prefix in forbiddenDeclarationPrefixes {
                    #expect(!source.contains(prefix), "\(sourceURL.path) should not contain public generated declarations.")
                }
                for token in forbiddenGeneratedExtensions {
                    #expect(!source.contains(token), "\(sourceURL.path) should not expose unused generated gRPC descriptor extensions.")
                }
            }
        }

        #expect(checkedFileCount > 0, "Generated proto source files should be checked.")
    }

    @Test("FirestoreAdmin transaction run throws typed access token error")
    func testFirestoreAdminTransactionRunThrowsTypedAccessTokenError() async {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())

        var didThrowInvalidAccessToken = false
        do {
            let _: Int? = try await firestore.runTransaction { _ in
                1
            }
        } catch FirestoreError.invalidAccessToken(_) {
            didThrowInvalidAccessToken = true
        } catch {
            didThrowInvalidAccessToken = false
        }

        #expect(didThrowInvalidAccessToken)
    }

    @Test("FirestoreAdmin transaction commit throws database mismatch")
    func testFirestoreAdminTransactionCommitThrowsDatabaseMismatch() async {
        let firestore = FirestoreAdmin(projectId: "expected-project", transport: MockClientTransport())
        let transaction = FirestoreAdminTransaction(
            database: firestore.database,
            runtime: firestore.transactionRuntime
        )
        let otherReference = DocumentReference(
            Database(projectId: "actual-project"),
            parentPath: "users",
            documentID: "user123"
        )
        transaction.setData(["name": "Ada"], forDocument: otherReference)

        var didThrowDatabaseMismatch = false
        do {
            try await transaction.commit()
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            didThrowDatabaseMismatch = expected == "projects/expected-project/databases/(default)"
                && actual == "projects/actual-project/databases/(default)"
        } catch {
            didThrowDatabaseMismatch = false
        }

        #expect(didThrowDatabaseMismatch)
    }

    @Test("FirestoreAdmin transaction query read after write throws")
    func testFirestoreAdminTransactionQueryReadAfterWriteThrows() async throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())
        let transaction = FirestoreAdminTransaction(
            database: firestore.database,
            runtime: firestore.transactionRuntime
        )
        transaction.setData(["name": "Ada"], forDocument: try firestore.document("users/user123"))

        var didThrowReadAfterWrite = false
        do {
            let query = try firestore.collection("users").whereField("active", isEqualTo: true)
            _ = try await transaction.get(query: query)
        } catch FirestoreError.readAfterWriteError {
            didThrowReadAfterWrite = true
        } catch {
            didThrowReadAfterWrite = false
        }

        #expect(didThrowReadAfterWrite)
    }

    @Test("FirestoreAdmin transaction getDocument read after write throws")
    func testFirestoreAdminTransactionGetDocumentReadAfterWriteThrows() async throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())
        let transaction = FirestoreAdminTransaction(
            database: firestore.database,
            runtime: firestore.transactionRuntime
        )
        let reference = try firestore.document("users/user123")
        transaction.setData(["name": "Ada"], forDocument: reference)

        var didThrowReadAfterWrite = false
        do {
            _ = try await transaction.getDocument(reference)
        } catch FirestoreError.readAfterWriteError {
            didThrowReadAfterWrite = true
        } catch {
            didThrowReadAfterWrite = false
        }

        #expect(didThrowReadAfterWrite)
    }

    @Test("FirestoreAdmin transaction supports SDK-compatible write methods")
    func testFirestoreAdminTransactionSupportsSDKCompatibleWriteMethods() async throws {
        let firestore = FirestoreAdmin(projectId: "expected-project", transport: MockClientTransport())
        let transaction = FirestoreAdminTransaction(
            database: firestore.database,
            runtime: firestore.transactionRuntime
        )
        let reference = try firestore.document("users/user123")
        let otherReference = DocumentReference(
            Database(projectId: "actual-project"),
            parentPath: "users",
            documentID: "user456"
        )
        _ = try transaction
            .create(data: ["created": true], forDocument: reference)
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
            try await transaction.commit()
        } catch FirestoreError.databaseMismatch(let expected, let actual) {
            didThrowDatabaseMismatch = expected == "projects/expected-project/databases/(default)"
                && actual == "projects/actual-project/databases/(default)"
        } catch {
            didThrowDatabaseMismatch = false
        }

        #expect(didThrowDatabaseMismatch)
    }

    @Test("FirestoreAdmin read-only transaction rejects writes")
    func testFirestoreAdminReadOnlyTransactionRejectsWrites() async throws {
        let firestore = FirestoreAdmin(projectId: "test", transport: MockClientTransport())
        let transaction = FirestoreAdminTransaction(
            database: firestore.database,
            runtime: firestore.transactionRuntime,
            options: TransactionOptions(readOnly: true)
        )
        transaction.setData(["name": "Ada"], forDocument: try firestore.document("users/user123"))

        var didThrowReadOnlyWrite = false
        do {
            try await transaction.commit()
        } catch FirestoreError.readOnlyTransactionWrite {
            didThrowReadOnlyWrite = true
        } catch {
            didThrowReadOnlyWrite = false
        }

        #expect(didThrowReadOnlyWrite)
    }

    @Test("Removed non-canonical Admin aliases stay absent")
    func testRemovedNonCanonicalAdminAliasesStayAbsent() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcePaths = [
            "Sources/FirestoreAdmin/FirestoreAdmin.swift",
            "Sources/FirestoreCore/CollectionReference.swift",
            "Sources/FirestoreCore/DocumentReference.swift",
            "Sources/FirestoreAdmin/FirestoreAdminWriteBatch.swift",
            "Sources/FirestoreAdmin/FirestoreAdminTransaction.swift"
        ]
        let source = try sourcePaths
            .map { try String(contentsOf: rootURL.appending(path: $0), encoding: .utf8) }
            .joined(separator: "\n")
        let forbiddenTokens = [
            "@available(*, deprecated",
            "func collectionReference(",
            "func documentReference(",
            "func collectionGroupReference(",
            "func setData(data:",
            "func updateData(fields:",
            "func deleteDocument(document:",
            "func get(documentReference:",
            "func create(documentReference:",
            "func set(documentReference:",
            "func update(documentReference:",
            "func delete(documentReference:"
        ]

        for token in forbiddenTokens {
            #expect(!source.contains(token), "Removed non-canonical Admin alias should stay absent: \(token).")
        }
    }
}
