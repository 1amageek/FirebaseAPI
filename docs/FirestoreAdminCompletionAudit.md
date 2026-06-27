# Firestore Admin Completion Audit

Status: Local implementation and emulator verification completed; live Firestore smoke pending credentials

Last reviewed: 2026-06-28

## Objective

FirebaseAPI should expose a Firebase iOS SDK-compatible Firestore Admin surface for server-side Swift. The API should keep familiar SDK naming where the Firestore semantics match, but avoid client-only features and keep RPC/protobuf/transport details out of user-facing code.

## Requirement Evidence

| Requirement | Evidence | Status |
|---|---|---|
| Server-side Admin facade exists | `FirestoreAdmin` owns the public server workflow surface, and `FirestoreAdminServer` is the preferred product import. | Verified locally |
| Firebase iOS SDK-compatible naming is used where semantics match | `collection(_:)`, `document(_:)`, `whereField(...)`, snapshot cursor, aggregation, Codable, listener, batch, transaction, and source/listen compatibility APIs are documented in `FirestoreAdminCompatibility.md` and covered by API safety tests. | Verified locally |
| Client-only SDK behavior is excluded or rejected | Offline cache, network toggles, pending-write APIs, cache source reads/listeners, and `FirebaseApp` authentication are documented as excluded or server-side rejected, with safety tests guarding symbol leakage. | Verified locally |
| gRPC/protobuf implementation does not leak into public API | Generated output lives in `FirestoreProtobuf` and `FirestoreGRPCStubs` with package visibility; release readiness dumps the public symbol graph and rejects protobuf, gRPC transport, and internal compiler symbols. | Verified locally |
| RPC usage is centralized and readable | Native request compilation lives in `FirestoreRPC`, Pipeline request compilation lives in `FirestorePipelineRPC`, and generated client calls live in `FirestoreGRPCTransport` operation wrappers. Release readiness checks client call ownership and request wrapper ownership. | Verified locally |
| Responsibility boundaries are split by dependency reason | Core, Embedded, AuthCore, Auth, RuntimeConfig, Codable, Admin, AdminCodable, AdminGRPCBootstrap, AdminServer, GeoQuery, MongoCore, RPC, PipelineRPC, RuntimeSupport, Protobuf, GRPCStubs, and GRPCTransport are separate targets. | Verified locally |
| Public products are limited to intended adoption surfaces | `Package.swift` exposes only `FirestoreAdminServer`, `FirestoreEmbedded`, `FirestoreMongoCore`, and compatibility `FirestoreAPI` as public library products. | Verified locally |
| Public Admin import surface is curated | `FirestoreAdminServer` re-exports exactly the server-side Admin modules and excludes Mongo-compatible query documents, RPC compilers, Pipeline RPC compilers, gRPC transport, generated protobuf, generated gRPC stubs, and runtime-support seams. | Verified locally |
| Compatibility import surface is curated | `FirestoreAPI` re-exports exactly the compatibility modules, including `FirestoreMongoCore` only for existing all-in-one imports, while excluding RPC compilers, Pipeline RPC compilers, gRPC transport, generated protobuf, generated gRPC stubs, and runtime-support seams. | Verified locally |
| Swift package dependencies are up to date | `swift package update` reports that the current dependency graph is already up to date, including grpc-swift-2, grpc-swift-nio-transport, grpc-swift-protobuf, swift-protobuf, swift-crypto, and swift-log. | Verified locally |
| Public Auth surface is curated | `FirestoreAuthCore` exposes only token-provider contracts and Firestore scopes. `FirestoreAuth` exposes service account credentials, service account token provider, metadata server providers, and ADC resolution; test requester/response types and credential private key fields remain non-public. | Verified locally |
| Firestore protobuf inputs are current | The `goolgeapis` submodule is at upstream `googleapis/googleapis` `HEAD` `0a38d04e5f6c265e74a994240b762c22666329a5` as verified by `git ls-remote`, and Firestore protobuf/gRPC stubs were regenerated after the update. | Verified locally |
| Application Default Credentials follow supported server-side search order | `FirestoreAuth` resolves `GOOGLE_APPLICATION_CREDENTIALS`, the gcloud well-known ADC file, and the metadata server in order for supported server credential flows. Unsupported ADC file types are rejected explicitly. | Verified locally |
| Aggregation, Explain, vector, Pipeline, and subquery support are present | Compiler and runtime contract tests cover Core aggregation, Query Explain, vector nearest, Pipeline Explain, Pipeline stages/functions, DML, and `subcollection(...)` subquery-only validation. | Verified locally |
| Native GeoQuery is supported | `FirestoreGeoQuery` owns geohash range planning and exact distance filtering. Emulator tests cover native GeoQuery execution. | Verified locally |
| MongoDB-compatible geospatial support is separate | `FirestoreMongoCore` owns `$near`, `$geometry`, GeoJSON, and `2dsphere` query/index documents; `FirestoreAdminServer` does not re-export it. | Verified locally |
| Embedded Swift support is separate | `FirestoreEmbedded` owns dependency-free value, reference, filter, and query descriptors and is verified with `scripts/check-embedded-readiness.sh`. Admin/gRPC execution remains outside the Embedded Swift product. | Verified locally |
| Emulator-backed real RPC behavior works | Firestore emulator integration tests cover CRUD, query, count, listen, compound AND/OR filters, array-membership OR branches, listen reconnect after TCP drop, `limit(toLast:)` snapshot cursors, native GeoQuery, and opt-in Pipeline aggregation/DML/subquery smoke execution. | Verified locally |
| Production Firestore smoke path exists | `FirestoreLiveIntegrationTests` runs Admin CRUD, query, and count when `FIRESTORE_LIVE_SMOKE=1` and Application Default Credentials are configured. It uses `applicationDefaultResolvingProjectID(...)` so service account, project environment variable, and metadata server project ID resolution paths are supported. | Test added, not executed in this environment |

SwiftPM can make transitive implementation targets visible to consumers that depend on a library product. The boundary enforced here is therefore public API visibility, not absolute module import invisibility: implementation modules use `package` or `internal` declarations, `FirestoreAdminServer` does not re-export those modules, and release readiness rejects implementation symbols in the public symbol graph.

## Verification Commands

| Command | Result |
|---|---|
| `swift build --configuration debug` | Passed |
| `swift package update` | Passed; dependency graph was already up to date |
| `git ls-remote https://github.com/googleapis/googleapis.git HEAD` | Matched local `goolgeapis` `HEAD` `0a38d04e5f6c265e74a994240b762c22666329a5` |
| `./scripts/generate-firestore-protos.sh` | Passed after updating `goolgeapis` |
| `bash scripts/check-embedded-readiness.sh` | Passed with Swift 6.3.1 Embedded Swift toolchain |
| `perl -e 'alarm shift; exec @ARGV' 120 xcodebuild -quiet -scheme FirebaseAPI-Package -destination 'platform=macOS' test -only-testing:FirebaseAPITests/ServerSideAPISafetyTests` | Passed |
| `perl -e 'alarm shift; exec @ARGV' 180 xcodebuild -quiet -scheme FirebaseAPI-Package -destination 'platform=macOS' test -only-testing:FirebaseAPITests/RPCCompilerTests -only-testing:FirebaseAPITests/RPCRuntimeContractTests` | Passed |
| `bash scripts/check-release-readiness.sh` | Passed |
| `FIRESTORE_LIVE_SMOKE=1 FIRESTORE_LIVE_DIAGNOSTICS_ONLY=1 bash scripts/run-live-firestore-smoke.sh` | Passed diagnostics-only mode |
| Firestore emulator integration test via `firebase emulators:exec` | Passed |
| Firestore emulator Pipeline smoke via `FIRESTORE_EMULATOR_PIPELINE_SMOKE=1` | Passed |

## Remaining Risk

The only unproven runtime path is a live production Firestore smoke test with real Google credentials. The test is implemented but intentionally opt-in so normal local and CI runs do not create remote documents.

To close that risk, configure Application Default Credentials and run:

```bash
FIRESTORE_LIVE_SMOKE=1 \
FIRESTORE_LIVE_PROJECT_ID=<project-id> \
bash scripts/run-live-firestore-smoke.sh
```

To inspect credential and project-ID candidates without running production RPCs:

```bash
FIRESTORE_LIVE_SMOKE=1 \
FIRESTORE_LIVE_DIAGNOSTICS_ONLY=1 \
bash scripts/run-live-firestore-smoke.sh
```

`FIRESTORE_LIVE_DATABASE_ID` can be set when testing a non-default database.
