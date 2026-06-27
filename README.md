# FirebaseAPI

FirebaseAPI for Swift is a Swift package that provides a simple interface to interact with Firebase services using gRPC.

This repository includes the [googleapis](https://github.com/googleapis/googleapis) repository as a submodule, which is used to generate the API client code for Firebase.

## Features

- ✅ **Server-side Admin API**: Non-generic `FirestoreAdmin` facade for server applications
- ✅ **Google Auth**: Service account JWT bearer flow and Application Default Credentials support
- ✅ **Firestore API**: Support for Firestore operations (CRUD, queries, transactions, batches)
- ✅ **Bulk Writer**: Server-side non-atomic `BatchWrite` support with per-write status results
- ✅ **Server-side Reference Listing**: `ListCollectionIds` and `ListDocuments` support for Admin reference discovery
- ✅ **Aggregation and Explain**: Core `count`, `sum`, `average`, Query Explain, and aggregation Explain support
- ✅ **Partition Query**: Server-side collection-group partition planning without exposing protobuf cursors
- ✅ **Firestore Pipeline**: ExecutePipeline support with typed stages, subqueries, Pipeline Search, Pipeline geospatial distance expressions, DML stages, and Pipeline Explain
- ✅ **Vector Search**: Core `findNearest` query support plus Firestore Pipeline vector nearest and distance functions
- ✅ **GeoQuery**: Native Firestore geohash range queries with GeoPoint distance filtering
- ✅ **Mongo-Compatible Geo Query Documents**: Separate Mongo-compatible GeoJSON `$near` query and `2dsphere` index builders without mixing them into Native Query
- ✅ **Embedded Swift Descriptors**: Dependency-free `FirestoreEmbedded` product for Firestore-compatible value, reference, and query descriptors in Embedded Swift builds
- ✅ **Transport-backed Runtime**: Support for any `ClientTransport` implementation from grpc-swift-2 without leaking transport types through app code
- ✅ **Swift 6 Ready**: Full concurrency support with `async/await` and `Sendable`
- ✅ **Type-safe Encoding/Decoding**: FirestoreEncoder and FirestoreDecoder for seamless Swift type conversion
- ✅ **Property Wrappers**: `@DocumentID`, `@ReferencePath`, `@ExplicitNull`, and `@ServerTimestamp` for Firestore-specific behaviors
- ✅ **Retry Strategy**: Built-in retry handling with exponential backoff

## Requirements

- Swift 6.2+
- macOS 15.0+ / iOS 18.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+

## Installation

Add FirebaseAPI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/FirebaseAPI.git", from: "2.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FirestoreAdminServer", package: "FirebaseAPI")
    ]
)
```

`FirestoreAdminServer` is the preferred server-side Firestore Admin product. `FirestoreAPI` remains available as a source-compatible all-in-one import for existing applications. Add the `FirestoreMongoCore` product explicitly only when building MongoDB-compatible query documents. Add the `FirestoreEmbedded` product explicitly for Embedded Swift value/reference/query descriptors; it does not include gRPC, protobuf, authentication, Codable, or network execution.

## Usage

### Initialize Firestore

```swift
import FirestoreAdminServer

let credentials = try ServiceAccountCredentials.load(from: serviceAccountJSONURL)
let firestore = try FirestoreAdmin(credentials: credentials)
```

For environments configured with Application Default Credentials:

```swift
let firestore = try FirestoreAdmin.applicationDefault()
```

For Google Cloud runtimes that rely on the metadata server for both tokens and project ID:

```swift
let firestore = try await FirestoreAdmin.applicationDefaultResolvingProjectID()
```

For local Firestore emulator development:

```swift
let firestore = try FirestoreAdmin.emulator(
    projectId: "demo-project",
    host: "127.0.0.1",
    port: 18080
)
```

### Lifecycle

Call `shutdown()` during service teardown so the underlying gRPC client stops accepting new RPCs and drains in-flight requests.

```swift
await firestore.shutdown()
```

### Embedded Swift Descriptors

`FirestoreEmbedded` is a separate dependency-free product for embedded environments that need Firestore-compatible descriptors without the Admin transport stack.

```swift
import FirestoreEmbedded

let database = try FirestoreEmbeddedDatabase(projectID: "demo-project")
let query = try FirestoreEmbeddedQuery(database: database, collectionPath: "devices")
    .where(.field("active", .equal, .bool(true)))
    .order(by: "updatedAt", descending: true)
    .limit(to: 10)
```

`FirestoreAdminServer` and `FirestoreAPI` are not Embedded Swift products because they depend on Foundation, authentication, Codable, protobuf, grpc-swift, and network transport.

### Basic CRUD Operations

```swift
// Define your model
struct User: Codable {
    @DocumentID var id: String
    var name: String
    var email: String
    var createdAt: Timestamp
}

// Create a document
let userRef = try firestore.collection("users").document("user123")
try await userRef.setData([
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": Timestamp.now()
])

// Or use Codable
let user = User(id: "user123", name: "John Doe", email: "john@example.com", createdAt: .now())
try await userRef.setData(from: user)

// Read a document
let snapshot = try await userRef.getDocument()
if let data = snapshot.data() {
    print("User data: \(data)")
}

// Or decode to Codable
let user: User? = try await userRef.getDocument(as: User.self)

// Update a document
try await userRef.updateData(["name": "Jane Doe"])

// Delete a document
try await userRef.delete()
```

### Queries

```swift
// Simple query
let usersRef = try firestore.collection("users")
let snapshot = try await usersRef
    .whereField("age", isGreaterThanOrEqualTo: 18)
    .whereField("city", isEqualTo: "Tokyo")
    .order(by: "name", descending: false)
    .limit(to: 10)
    .getDocuments()

for doc in snapshot.documents {
    print(doc.data())
}

// Query with Codable
let users: [User] = try await usersRef
    .whereField("age", isGreaterThanOrEqualTo: 18)
    .getDocuments(as: User.self)
```

### Geo Queries

Native Firestore geo queries use a geohash string field and a GeoPoint field. FirebaseAPI runs the required geohash range queries and filters the final result by exact distance.

```swift
let places = try firestore.collection("places")
let location = GeoPoint(latitude: 37.4219999, longitude: -122.0840575)

try await places.document("googleplex").setData([
    "geohash": try FirestoreGeoHash.encode(location),
    "location": location
])

let results = try await places
    .geoQuery(
        center: location,
        radiusInMeters: 1_000,
        geohashField: "geohash",
        locationField: "location"
    )
    .getDocuments()

for result in results {
    print(result.document.id, result.distanceInMeters)
}
```

Enterprise Native Pipeline geospatial search is modeled separately from geohash GeoQuery and Mongo-compatible `$near` queries. Use `PipelineValue.geoDistance(to:)` inside `FirestorePipeline.search(query:sort:addFields:)` when a Pipeline Search predicate should compare Firestore GeoPoint distance.

### Transactions

```swift
try await firestore.runTransaction { transaction in
    // Read documents
    let userDoc = try firestore.document("users/user123")
    let snapshot = try await transaction.getDocument(userDoc)

    let balance = snapshot.data()?["balance"] as? Int ?? 0

    // Write operations
    transaction.updateData(["balance": balance - 100], forDocument: userDoc)

    return balance - 100
}
```

### Batch Writes

```swift
let batch = firestore.batch()

let user1 = try firestore.document("users/user1")
let user2 = try firestore.document("users/user2")

batch.setData(["name": "Alice"], forDocument: user1)
batch.updateData(["lastLogin": Timestamp.now()], forDocument: user2)
batch.deleteDocument(try firestore.document("users/user3"))

try await batch.commit()
```

### Bulk Writes

```swift
let writer = firestore.bulkWriter()

let user1 = try firestore.document("users/user1")
let user2 = try firestore.document("users/user2")

writer.setData(["name": "Alice"], forDocument: user1)
writer.deleteDocument(user2)

let result = try await writer.flush(labels: ["job": "backfill"])
```

`bulkWriter()` uses Firestore `BatchWrite`, which is not atomic and can return partial success. Inspect `FirestoreBulkWriteResult.results` for per-write status. Use `batch().commit()` when the writes must be atomic.

Individual document writes, atomic batches, and transactions use Firestore `Commit`. Low-level `CreateDocument`, `UpdateDocument`, `DeleteDocument`, and streaming `Write` RPCs are kept out of the public Admin API so write masks, transforms, and preconditions stay on the same compiler path.

### Property Wrappers

```swift
struct Post: Codable {
    @DocumentID var id: String
    @ReferencePath var path: String
    @ExplicitNull var deletedAt: Date?

    var title: String
    var content: String
    var authorRef: DocumentReference
}

// @DocumentID: Automatically populated with document ID during decoding
// @ReferencePath: Automatically populated with document path
// @ExplicitNull: Encodes as NSNull instead of omitting the field
```

## Architecture

### Server-side Admin Facade

Application code should use `FirestoreAdmin`. It keeps the public API non-generic while the internal runtime remains backed by a concrete grpc-swift transport.

```swift
import FirestoreAdminServer

let credentials = try ServiceAccountCredentials.load(from: serviceAccountJSONURL)
let firestore = try FirestoreAdmin(credentials: credentials)
```

### Runtime and RPC Boundaries

The implementation is split into these responsibilities:

- **Public facade**: `FirestoreAdmin` and server-side Admin builders such as `FirestoreAdminWriteBatch` and `FirestoreAdminBulkWriter`
- **Recommended server-side product**: `FirestoreAdminServer` re-exports the Admin facade, Admin Codable helpers, gRPC bootstrap, Auth, Core, Codable, Pipeline, RuntimeConfig, and Native GeoQuery targets without re-exporting Mongo-compatible query documents or RPC/transport implementation targets
- **Compatibility import surface**: `FirestoreAPI` re-exports the dedicated `FirestoreAdmin`, `FirestoreAdminCodable`, Core, Codable, Pipeline, Auth, Native GeoQuery, and Mongo-compatible query document targets so existing applications can keep importing one module
- **Embedded boundary**: `FirestoreEmbedded` owns dependency-free Firestore value, reference, and query descriptors for Embedded Swift builds; it does not depend on Core, Codable, protobuf, gRPC, Auth, or transport modules
- **Admin write staging**: `FirestoreAdminWriteBuffer` centralizes internal write buffering, database validation, read-only transaction rejection, and BulkWriter duplicate-document checks
- **Reference/query core**: `DocumentReference`, `CollectionReference`, `CollectionGroup`, `Query`, snapshots, path construction, query planning state, and runtime delegation without grpc-swift transport dependencies
- **Codable boundary**: `FirestoreCodable` owns `FirestoreEncoder`, `FirestoreDecoder`, Firestore property wrappers, and reference/query/snapshot Codable convenience extensions; `FirestoreAdminCodable` owns Admin builder and transaction Codable overloads
- **Native GeoQuery boundary**: `FirestoreGeoQuery` owns geohash range planning, `FirestoreGeoHash`, and exact Swift distance filtering
- **Mongo-compatible boundary**: `FirestoreMongoCore` owns GeoJSON `$near` query documents and `2dsphere` index declarations; future Mongo-compatible transport work must stay outside Native Query, Native GeoQuery, and Pipeline
- **Auth boundary**: service account credential loading, OAuth access token minting, token caching, and explicit emulator-only disabled authentication; private key material is consumed by the token provider and is not exposed as public credential state
- **Runtime configuration boundary**: `FirestoreRuntimeConfig` owns `FirestoreSettings`, retry policy, log level, and authentication mode so Core model files stay focused on Firestore values and query state
- **Runtime protocol boundary**: `FirestoreCore` owns reference/query/listen/partition runtime seams; `FirestoreRuntimeSupport` owns batch/Pipeline runtime seams and the facade composition `FirestoreRuntime`, all without grpc-swift transport types
- **gRPC transport boundary**: `FirestoreGRPCTransport` owns transport lifecycle, authorization metadata, database validation, and RPC dispatch
- **RPC compilers**: query, write, batch write, and listen target protobuf message construction, pre-RPC validation, and SDK-level query normalization such as `limitToLast`
- **Listen state reducers**: conversion from raw Firestore `ListenResponse` events into user-facing document/query snapshots and document changes
- **gRPC operation layer**: request execution, retry wrapping, response streaming, and delivery of reducer output required by compiled query plans

### RPC Query Planning

Firestore's gRPC API does not expose every SDK-level query concept directly. The `QueryCompiler` owns this translation before requests reach the transport layer:

- `limit(to:)` is compiled to a structured query limit.
- `limit(toLast:)` requires at least one explicit `order(by:)`, reverses the RPC order clauses, swaps start/end cursors when present, and marks the run-query plan so the runtime restores the user-visible result order.
- `start(at:)`, `start(after:)`, `end(at:)`, and `end(before:)` are compiled to structured query cursors and require at least one explicit `order(by:)`. `CollectionReference` and `CollectionGroup` expose the same cursor surface by forwarding through `Query`.
- Field-value cursors ordered by `FieldPath.documentID()` are converted from SDK-style string document IDs into Firestore reference values by `QueryCompiler`. Collection queries require a plain document ID; collection-group queries require a valid document path.
- `start(atDocument:)`, `start(afterDocument:)`, `end(atDocument:)`, and `end(beforeDocument:)` convert an existing `DocumentSnapshot` or `QueryDocumentSnapshot` into ordered cursor values before `QueryCompiler` builds the RPC cursor. Document snapshot cursors use normalized ordering: missing inequality order fields are appended, the document key is always included last, and the key direction follows the last explicit order or ascending when none exists. The snapshot must exist, belong to the same database, and contain every ordered field that is not the document key.
- `CollectionGroup.partitionedQueries(partitionPointCount:pageSize:readTime:)` uses Firestore `PartitionQuery` to return executable `Query` ranges ordered by `FieldPath.documentID()`. Protobuf `Cursor` values stay inside the RPC mapper.
- Native `geoQuery(...)` composes `order(by:)`, `start(at:)`, and `end(at:)` over a geohash field, then filters snapshots by GeoPoint distance.
- Query limits must be greater than or equal to zero and are rejected before the request is sent when outside Firestore's supported range.

The runtime must execute compiled plans instead of rebuilding protobuf messages directly.

### Listener Snapshot Semantics

Document and query listeners are reduced through `DocumentListenState` and `QueryListenState` instead of exposing raw gRPC events as user snapshots:

- `TargetChange.current` is the initial snapshot boundary. Document changes received before that point are emitted as one initial snapshot.
- Document listeners emit an initial missing snapshot when the target becomes current without a document.
- The initial query snapshot reports all currently matching documents as `DocumentChangeType.added`.
- Subsequent document updates emit `added`, `modified`, or `removed` changes with reducer-computed `oldIndex` and `newIndex`.
- Query snapshots are ordered with the user-visible `order(by:)` clauses. When an ordered field changes, the reducer recomputes the document position and reports the move through `oldIndex` and `newIndex`.
- Snapshot metadata is exposed as `SnapshotMetadata`; server-side Admin snapshots are currently synchronized server snapshots with `hasPendingWrites == false` and `isFromCache == false`.
- `ExistenceFilter` count mismatches request an internal listener resync. The gRPC runtime opens a fresh listen target and retries up to the configured retry limit instead of emitting an inconsistent snapshot.
- `TargetChange.resumeToken` is retained by the reducer. Retryable stream errors reconnect with the latest token; `ExistenceFilter` mismatch clears the token and performs a full resync.

The reducer preserves the listen stream document order and no longer sorts snapshots by document path.

### Query Constraint Validation

`QueryConstraintValidator` runs before protobuf request construction. It enforces Firestore Standard edition and RPC query limits that are otherwise easy to discover only after a remote failure:

- DNF expansion for `or`, `in`, and `arrayContainsAny` is limited to 30 disjunctions.
- `notIn` is limited to 10 values and cannot be combined with `or`, `in`, `arrayContainsAny`, or `notEqual`.
- Only one `arrayContains` is allowed per disjunction, and it cannot share a disjunction with `arrayContainsAny`.
- Explicit `order(by:)` on inequality queries must start with one of the inequality fields.
- Queries can use at most 10 range or inequality fields.
- The sum of filters, sort orders, and parent document path cost must not exceed 100 after DNF expansion.

### Field Path Semantics

The public API accepts both SDK-style string field paths and typed `FieldPath` values:

- `setData(..., merge:)` treats dictionary keys as literal document field names and quotes RPC mask segments when needed.
- `updateData(...)` treats string keys as SDK-style field paths, matching Firebase client SDK behavior.
- `FieldPath` stores field names as explicit segments, so names containing `.` or other non-simple characters are encoded with Firestore RPC quoting rules.
- `FieldPath.documentID()` is compiled to Firestore's `__name__` reference field and document reference values.
- Core aggregation fields use the same SDK-style string field path normalization before `RunAggregationQuery` request construction.
- `FieldValue.delete()` and `FieldValue.serverTimestamp()` are available as SDK-style factories while preserving the existing sentinel values.
- `@ServerTimestamp` encodes nil Codable timestamp fields as `FieldValue.serverTimestamp()` before write compilation and decodes missing or null timestamp fields as nil.
- `@ExplicitNull` decodes missing or null optional fields as nil.
- `FieldValue.increment(Int/Int64)` preserves integer transforms, while `FieldValue.increment(Double)` preserves double transforms.
- `Data` maps to Firestore `bytes_value` for Codable writes and reads.
- `FieldValue.vector(...)` returns a `FirestoreVector` value for SDK-style vector writes. Firestore stores the current vector representation as an array value, and `FirestoreDecoder` restores that array into `FirestoreVector` when the Codable model asks for that type.
- `DocumentSnapshot.data(as:)`, `QueryDocumentSnapshot.data(as:)`, and `QuerySnapshot.documents(as:)` decode already-fetched snapshots through the same `FirestoreDecoder` path used by typed read helpers.
- `DocumentSnapshot.get(...)`, `QueryDocumentSnapshot.get(...)`, snapshot subscripts, and `data(with:)` provide SDK-style field lookup. String field paths address nested maps, typed `FieldPath` preserves literal segments, `QueryDocumentSnapshot.data()` is non-optional because query results contain existing documents, and `ServerTimestampBehavior` is accepted as a server-side no-op because Admin reads only synchronized server values.
- `DocumentSnapshot.reference`, `DocumentSnapshot.documentID`, `QueryDocumentSnapshot.reference`, and `QueryDocumentSnapshot.documentID` mirror Firebase SDK snapshot naming while the existing `id` aliases continue to satisfy `Identifiable`.
- Document snapshot cursors use the same snapshot field lookup path and do not expose protobuf cursor values through public API.
- `DocumentReference.getDocument(as:)`, `CollectionReference.getDocuments(as:)`, `CollectionGroup.getDocuments(as:)`, and `Query.getDocuments(as:)` are SDK-style typed read aliases over the same server-side decoder path.
- `getDocument(source:)` and `getDocuments(source:)` accept SDK-style `FirestoreSource`; `.default` and `.server` use live server RPCs, while `FirestoreSource.cache` is rejected because server-side Admin has no local cache.
- `DocumentReference.setData(from:)` is the SDK-style Codable write alias; existing dictionary writes still use server-side `setData(_:)`.
- `FirestoreAdminTransaction.getDocument(_:type:)` and `get(query:type:)` provide typed reads inside server-side transactions.
- `DocumentReference.snapshots`, `CollectionReference.snapshots`, `CollectionGroup.snapshots`, `Query.snapshots`, `snapshots(includeMetadataChanges:)`, and `snapshots(options:)` are the canonical server-side listener API. Collection and collection-group listeners forward through `Query` so RPC compilation stays centralized. `addSnapshotListener(includeMetadataChanges:)` and `addSnapshotListener(options:)` remain compatibility aliases over the same server Listen RPC. `ListenSource.cache` is rejected because there is no local cache.
- Aggregation aliases, vector distance result fields, literal document data keys, and write mask field paths are validated as Firestore document field names, including reserved-name and parent/child conflict rejection where the RPC expects stored document fields.
- Explicit `mergeFields` writes reject missing data values and only send transforms covered by the requested merge field paths.
- Firestore Pipeline field references and vector nearest field options use the same field path normalization before `ExecutePipeline` request construction.
- Firestore Pipeline input stages, `subcollection(...)` subquery context, stage options, function options, variables, lambda parameters, and document reference database ownership are validated before `ExecutePipeline` request construction.

### Design Boundary

The current Admin surface separates RPC construction from public reference/query types. The server-side compatibility boundary is recorded in [docs/FirestoreAdminCompatibility.md](docs/FirestoreAdminCompatibility.md).

SDK-style names such as `collection(_:)`, `document(_:)`, `whereField(...)`, `setData(_:forDocument:)`, and `getDocument(_:)` are the canonical public API. Older non-canonical aliases were removed before the stable Admin surface.

## Development

### Prerequisites

To develop this library, you need:
1. Swift 6.2+
2. Protocol Buffer compiler (`protoc`)
3. gRPC Swift plugins

### Generating Proto Files

This repository includes the googleapis as a submodule. To regenerate the Firestore proto files:

Generated protobuf and gRPC symbols are internal implementation details. Keep the generated visibility internal so the package public API remains the server-side Admin surface.

```bash
./scripts/generate-firestore-protos.sh
```

### Running Tests

The test suite uses **Swift Testing** framework (not XCTest):

```bash
perl -e 'alarm shift; exec @ARGV' 90 xcodebuild -scheme FirebaseAPI-Package -destination 'platform=macOS' test
```

The current suite should pass with 409 tests across 20 suites.

To run the full local release-readiness gate:

```bash
bash scripts/check-release-readiness.sh
```

The release-readiness gate also dumps the public symbol graph and fails if protobuf, gRPC transport, or internal query-planning symbols leak into the public API.

To run only the Embedded Swift product check:

```bash
bash scripts/check-embedded-readiness.sh
```

The current implementation and verification status is tracked in [docs/FirestoreAdminCompletionAudit.md](docs/FirestoreAdminCompletionAudit.md).

Firestore emulator integration is enabled when `FIRESTORE_EMULATOR_HOST` is set. Optional environment variables:

- `FIRESTORE_EMULATOR_PROJECT_ID`
- `FIRESTORE_EMULATOR_DATABASE_ID`
- `FIRESTORE_EMULATOR_PIPELINE_SMOKE=1` to run the opt-in Pipeline execution smoke tests

Live Firestore smoke testing is opt-in so normal local and CI runs do not create remote documents. Set `FIRESTORE_LIVE_SMOKE=1` with Application Default Credentials before running the test suite. Service account ADC can come from `GOOGLE_APPLICATION_CREDENTIALS`, the gcloud well-known ADC file, or a Google Cloud metadata server. Optional environment variables:

- `FIRESTORE_LIVE_PROJECT_ID`
- `FIRESTORE_LIVE_DATABASE_ID`

To run only the live Firestore smoke test:

```bash
FIRESTORE_LIVE_SMOKE=1 FIRESTORE_LIVE_PROJECT_ID=your-project-id bash scripts/run-live-firestore-smoke.sh
```

To print credential and project-ID diagnostics without running production RPCs:

```bash
FIRESTORE_LIVE_SMOKE=1 FIRESTORE_LIVE_DIAGNOSTICS_ONLY=1 bash scripts/run-live-firestore-smoke.sh
```

To run the emulator-backed integration test locally:

```bash
XDG_CONFIG_HOME=/tmp/firebase-cli-config firebase emulators:exec --only firestore --project firebase-api-emulator-test "perl -e 'alarm shift; exec @ARGV' 180 xcodebuild -scheme FirebaseAPI-Package -destination 'platform=macOS' test"
```

### Test Coverage

- ✅ Firestore Encoder/Decoder for all supported types
- ✅ Document reference path generation
- ✅ Query predicates and operators
- ✅ Query RPC planning for `limit(to:)` and `limit(toLast:)`
- ✅ Server-side `ListDocuments` document reference pagination
- ✅ Collection group `PartitionQuery` request construction and runtime paging
- ✅ Server-side `BulkWriter` facade and `BatchWrite` request/status mapping
- ✅ Query and Pipeline vector nearest request construction
- ✅ Pipeline Search geospatial distance expression request construction
- ✅ FieldValue sentinel write encoding
- ✅ Property wrappers (@DocumentID, @ReferencePath, @ExplicitNull)
- ✅ Real-time listener response processing
- ✅ Listener resume token capture and retryable stream reconnect planning
- ✅ Listen reconnect coordinator coverage for retryable stream failures and full resync token clearing
- ✅ RPC runtime contract coverage for `GetDocument`, `RunQuery`, RunQuery vector nearest, RunQuery Explain, `RunAggregationQuery`, RunAggregationQuery Explain, `ExecutePipeline`, ExecutePipeline vector nearest, ExecutePipeline Explain, `PartitionQuery`, `BatchWrite`, `ListDocuments`, `ListCollectionIds`, `BeginTransaction`, `BatchGetDocuments`, `Commit`, `Rollback`, and `Listen` add/remove target request payloads
- ✅ Firestore emulator dropped TCP connection coverage for listen reconnect behavior
- ✅ Server-side Admin facade and runtime-bound references
- ✅ Service account JWT bearer auth, ADC service account loading from environment or gcloud well-known files, and metadata server project ID resolution
- ✅ Firestore emulator configuration and integration coverage for CRUD, query, count, and listen
- ✅ Firestore emulator integration coverage for `limit(toLast:)` document snapshot cursors
- ✅ Firestore emulator integration coverage for compound AND/OR filters and array-membership OR branches
- ✅ Firestore emulator integration coverage for native GeoQuery
- ✅ Opt-in Firestore emulator smoke coverage for Pipeline aggregations, lambda expressions, DML, and subqueries
- ✅ Opt-in live Firestore smoke coverage for Admin CRUD, query, and count
- ✅ RPC query, write, and listen target compilation
- ✅ Mock transport for testing without network calls

## Dependencies

- [grpc-swift-2](https://github.com/grpc/grpc-swift-2): gRPC core and protocols
- [grpc-swift-nio-transport](https://github.com/grpc/grpc-swift-nio-transport): Default HTTP/2 client transport
- [grpc-swift-protobuf](https://github.com/grpc/grpc-swift-protobuf): Protobuf serialization
- [swift-protobuf](https://github.com/apple/swift-protobuf): Protocol Buffer runtime
- [swift-crypto](https://github.com/apple/swift-crypto): RSA signing for service account JWT assertions
- [swift-log](https://github.com/apple/swift-log): Logging infrastructure

## Migration from grpc-swift 1.x

This library has been migrated to **grpc-swift-2.x**. Key changes:

- `HPACKHeaders` → `Metadata`
- `ClientCall` → `ClientRequest` with new API
- Direct `GRPCClient` creation instead of connection pooling
- Bidirectional streaming now fully supported for real-time listeners

## Real-time Listeners

The library now supports real-time listeners for documents and queries using bidirectional streaming:

```swift
// Listen to document changes
let docRef = try firestore.collection("users").document("user123")

for try await snapshot in docRef.snapshots {
    if snapshot.exists {
        print("Document updated: \(snapshot.data())")
    } else {
        print("Document deleted or doesn't exist")
    }
}
```

```swift
// Listen to query changes
let query = try firestore.collection("users").whereField("age", isGreaterThanOrEqualTo: 18)

for try await snapshot in query.snapshots {
    print("Query results updated: \(snapshot.documents.count) documents")
    for doc in snapshot.documents {
        print(doc.data())
    }
}
```

Note: The stream will continue until cancelled or an error occurs. Use task cancellation to stop listening:

```swift
let task = Task {
    for try await snapshot in stream {
        // Process snapshot
    }
}

// Later: stop listening
task.cancel()
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
