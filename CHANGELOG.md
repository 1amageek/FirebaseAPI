# Changelog

## 2.0.0

### Breaking Changes

- Split the package into focused Firestore modules and products. `FirestoreAdminServer` is now the preferred server-side Admin product, `FirestoreMongoCore` is the explicit Mongo-compatible query document product, and `FirestoreAPI` remains the compatibility all-in-one import.
- Raised package requirements to Swift 6.2 and modern Apple platform baselines.
- Removed the old public gRPC-adjacent implementation surface from the compatibility target. Generated protobuf and gRPC stubs now live in package-internal implementation targets.
- Removed client-only Firebase iOS SDK behavior from the server Admin surface, including local cache and network toggle APIs.

### Added

- Server-side `FirestoreAdmin` facade with narrow Admin protocols for reference, write, transaction, Pipeline, and lifecycle workflows.
- gRPC-backed Admin bootstrap for service account credentials, Application Default Credentials, metadata server credentials, custom token providers, and local emulator settings.
- Firestore aggregation support for `count`, `sum`, and `average`, including aggregation Explain.
- Query Explain, vector `findNearest`, collection-group partition query planning, server-side reference listing, BulkWriter, transactions, and listen reconnect handling.
- Firestore Pipeline support, including typed stages, subqueries, Pipeline Search, DML stages, vector operations, geospatial distance expressions, and Pipeline Explain.
- Native geohash GeoQuery support with exact distance filtering.
- Separate MongoDB-compatible GeoJSON `$near` query and `2dsphere` index document builders.
- Release-readiness checks for public symbol leakage, RPC ownership boundaries, generated source containment, Native/Mongo responsibility separation, and live-smoke diagnostics.

### Changed

- Regenerated Firestore protobuf and gRPC stubs from the latest `googleapis/googleapis` submodule state at release preparation time.
- Updated dependencies to current compatible grpc-swift-2, grpc-swift-nio-transport, grpc-swift-protobuf, swift-protobuf, swift-crypto, and swift-log versions.
- Moved Firestore Codable conversion and property wrappers into `FirestoreCodable`.
- Moved transport lifecycle, generated client calls, retry policy execution, and authorization metadata into `FirestoreGRPCTransport`.
- Moved Native Firestore request compilation and response mapping into `FirestoreRPC`; moved Pipeline RPC compilation into `FirestorePipelineRPC`.

### Verification

- `swift build --configuration debug`
- `swift package update`
- `bash scripts/check-release-readiness.sh`
- Firestore emulator integration via `firebase emulators:exec`
- Firestore emulator Pipeline smoke via `FIRESTORE_EMULATOR_PIPELINE_SMOKE=1`
- RPC compiler and runtime contract tests

Production Firestore live smoke remains opt-in and requires Application Default Credentials plus a project ID.
