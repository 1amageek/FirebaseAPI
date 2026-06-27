# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

### Purpose

FirebaseAPI is a **server-side Swift** package that enables Firestore integration on platforms where the official Firebase SDK cannot run.

**Why this library exists:**
- The official Firebase SDK is designed for iOS/Android/Web clients and **does not support server-side Swift environments** (Linux, Vapor, Hummingbird, etc.)
- Server-side Swift applications need direct Firestore access without depending on client SDKs
- Existing solutions require Node.js or other runtimes, preventing pure Swift backend implementations

**What this library provides:**
- Native Swift interface to Google Cloud Firestore using gRPC
- Full compatibility with server-side Swift frameworks (Vapor, Hummingbird)
- Cross-platform support including Linux servers
- API design that closely mirrors official Firebase SDKs for familiarity
- Built entirely on Swift concurrency (async/await) and gRPC-Swift 2.x

**Primary use cases:**
- Backend services written in Swift (Vapor, Hummingbird)
- Command-line tools and scripts
- macOS server applications
- Linux-based cloud deployments
- Any Swift environment where official Firebase SDK is unavailable

## Core Architecture

### Server-Side Admin Abstraction
The library uses a **hierarchical reference model** similar to Firebase SDKs, but the entry point is server-side Admin:
- `FirestoreAdmin`: Root Admin facade that owns runtime dispatch and server-side lifecycle
- `CollectionReference`: Represents a Firestore collection path
- `DocumentReference`: Represents a specific document path
- `Query`: Represents a query with filters, ordering, and limits
- `CollectionGroup`: Queries across all collections with the same ID

### RPC and gRPC Integration Layers
Public API code, protobuf request compilation, and concrete grpc-swift transport execution are separate responsibilities:
- `Sources/FirestoreCore`: Protobuf-free model, query, reference, snapshot, value, source, listen, aggregation, vector, and error types
- `Sources/FirestoreAdmin`: Server-side Admin workflow facade and narrow dependency-injection protocols
- `Sources/FirestoreRPC`: Native Firestore request compilers, response mappers, query validation, and Listen reducers
- `Sources/FirestorePipelineRPC`: Firestore Pipeline request compiler and ExecutePipeline response mapper
- `Sources/FirestoreGRPCTransport`: Concrete grpc-swift transport lifecycle, authorization metadata, retry execution, and generated client calls
- `Sources/FirestoreProtobuf/Proto`: Generated protobuf messages
- `Sources/FirestoreGRPCStubs/Proto`: Generated gRPC stubs

This separation keeps public Admin workflow code free of protobuf, generated gRPC, and concrete transport details.

### Custom Codable Implementation
The library provides custom `FirestoreEncoder` and `FirestoreDecoder` in `Sources/FirestoreCodable/Cadable/`:
- Handles Firestore-specific types: `Timestamp`, `GeoPoint`, `DocumentReference`
- Supports special property wrappers: `@DocumentID`, `@ExplicitNull`, `@ReferencePath`, `@ServerTimestamp`
- Converts between Swift types and Firestore protocol buffer values

### Query System
Queries use a public `Filter` facade backed by package-internal `QueryPredicate` planning state:
- Predicates are accumulated in an array and composed into composite filters
- Supports field filters, unary filters, and composite filters (AND/OR)
- Special handling for document ID queries vs field queries
- `QueryCompiler` converts query state into Firestore `StructuredQuery` protobuf requests

### Transaction & Batch Writes
- `FirestoreAdminTransaction`: Atomic read-then-write operations with transaction-level retry
- `FirestoreAdminWriteBatch`: Atomic Commit-backed batched writes
- `FirestoreAdminBulkWriter`: Non-atomic BatchWrite-backed bulk writes with per-write status results

## Development Commands

### Build & Test
```bash
# Build the package
swift build --configuration debug

# Run all tests
perl -e 'alarm shift; exec @ARGV' 300 xcodebuild -quiet -scheme FirebaseAPI-Package -destination 'platform=macOS' test

# Build specific configuration
swift build -c release

# Run specific test
perl -e 'alarm shift; exec @ARGV' 120 xcodebuild -quiet -scheme FirebaseAPI-Package -destination 'platform=macOS' test -only-testing:FirebaseAPITests/FirestoreEncoderTests
```

### Protocol Buffer Generation
The project uses a googleapis submodule (`goolgeapis/`) to generate Firestore API bindings:

```bash
# Generate proto files (run from project root)
./scripts/generate-firestore-protos.sh
```

Generated protobuf files are in `Sources/FirestoreProtobuf/Proto/`; generated gRPC stubs are in `Sources/FirestoreGRPCStubs/Proto/`. They should not be manually edited.

### Testing Setup
Most tests run without external credentials. Firestore emulator integration uses `firebase emulators:exec`, and production Firestore smoke tests are opt-in through environment variables:
- `FIRESTORE_LIVE_SMOKE=1`
- `FIRESTORE_LIVE_PROJECT_ID`
- `GOOGLE_APPLICATION_CREDENTIALS` or another supported Application Default Credentials source

## Key Implementation Patterns

### Access Token Authentication
All Firestore operations require OAuth2 access tokens:
- Implement `AccessTokenProvider` protocol to supply tokens
- Prefer `FirestoreAdmin(credentials:)`, `FirestoreAdmin.applicationDefault()`, or `FirestoreAdmin.applicationDefaultResolvingProjectID()`
- Tokens are passed through gRPC metadata by `FirestoreGRPCTransport`

### Error Handling & Retry
- `FirestoreTransactionBackoff`: Retry logic for transactions (max attempts configurable)
- `FirestoreRetryHandler`: Actor-based retry with configurable strategies (exponential, linear, custom)
- `FirestoreError`: Custom error types for Firestore-specific failures

### Path Construction
All paths are normalized using `.normalized` extension on String to handle trailing slashes and empty components. Reference types validate path structure (collections have odd segments, documents have even segments).

### Property Wrappers
- `@DocumentID<String>`: Auto-populated with document ID during decoding, excluded from encoding unless explicitly set
- `@ExplicitNull`: Distinguishes between "field not set" and "field set to null"
- `@ReferencePath`: Encodes/decodes DocumentReference paths as strings

## Important Constraints

1. **Database Validation**: All write operations check that `document.database == firestore.database` before proceeding
2. **Path Validation**: Collection IDs and document IDs are validated for empty strings and invalid characters (no "/" allowed)
3. **Transaction Reads Before Writes**: Transactions enforce read-before-write (throws `FirestoreError.readAfterWriteError`)
4. **Concurrency Safety**: Uses Swift concurrency and package-internal runtime seams; public API code should not depend on concrete grpc-swift transport types

## Real-time Listeners

### Implementation Status: ✅ Completed

The library now fully supports real-time listeners using grpc-swift-2's bidirectional streaming API.

**Available APIs:**
- `DocumentReference.addSnapshotListener()` - Real-time document listeners
- `Query.addSnapshotListener()` - Real-time query listeners

**Implementation details:**
- `FirestoreListenStreamExecutor` owns concrete streaming gRPC request construction
- `ListenStreamCoordinator` owns target add/remove sequencing, retry, resume token, and full-resync control
- Returns `AsyncThrowingStream` for easy consumption with `for try await`

**Example usage:**
```swift
// Document listener
let docRef = firestore.collection("users").document("user123")
let stream = try await docRef.addSnapshotListener()
for try await snapshot in stream {
    print("Document updated: \(snapshot.data())")
}

// Query listener
let query = firestore.collection("users").whereField("age", isGreaterThanOrEqualTo: 18)
let stream = try await query.addSnapshotListener()
for try await snapshot in stream {
    print("Query results: \(snapshot.documents.count) documents")
}
```

**Implementation locations:**
- `Sources/FirestoreRPC/Listen/ListenStreamCoordinator.swift` - Listen reconnect and resume-token coordination
- `Sources/FirestoreRPC/Listen/DocumentListenState.swift` - Document listen response reduction
- `Sources/FirestoreRPC/Listen/QueryListenState.swift` - Query listen response reduction
- `Sources/FirestoreGRPCTransport/FirestoreListenStreamExecutor.swift` - Streaming gRPC request execution

**Note on testing:**
- Real-time listeners can be tested with the Firestore emulator
- Use task cancellation to stop listening: `task.cancel()`

## Code Organization

```
Sources/FirestoreAPI/
└── Compatibility re-export files
Sources/FirestoreAdmin/               Server-side Admin facade
Sources/FirestoreAdminServer/         Preferred server-side product re-exports
Sources/FirestoreCore/                Public model/query/reference/snapshot types
Sources/FirestoreEmbedded/            Dependency-free Embedded Swift descriptors
Sources/FirestoreCodable/             FirestoreEncoder, FirestoreDecoder, property wrappers
Sources/FirestoreRPC/                 Native Firestore compilers and response mappers
Sources/FirestorePipelineRPC/         Pipeline compiler and response mapper
Sources/FirestoreGRPCTransport/       Concrete grpc-swift transport execution
Sources/FirestoreProtobuf/Proto/      Generated protobuf files
Sources/FirestoreGRPCStubs/Proto/     Generated gRPC stub files
```

## Platform Support
- iOS 18+
- macOS 15+
- watchOS 11+
- tvOS 18+
- visionOS 2+
- Uses Swift 6.2+ (see Package.swift)
