# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FirebaseAPI is a Swift package that provides a native Swift interface to interact with Google Cloud Firestore using gRPC. It implements a Firestore client that closely mirrors the official Firebase SDKs but is built entirely on Swift concurrency (async/await) and gRPC-Swift.

## Core Architecture

### Client-Side Abstraction
The library uses a **hierarchical reference model** similar to Firebase SDKs:
- `Firestore`: Root client that manages gRPC connections and authentication
- `CollectionReference`: Represents a Firestore collection path
- `DocumentReference`: Represents a specific document path
- `Query`: Represents a query with filters, ordering, and limits
- `CollectionGroup`: Queries across all collections with the same ID

### gRPC Integration Layer
All API operations are implemented in separate `+gRPC.swift` extension files in `Sources/FirestoreAPI/gPRC/`:
- `Firestore+gRPC.swift`: Core Firestore operations (transactions, batch operations)
- `DocumentReference+gRPC.swift`: Document CRUD operations
- `CollectionReference+gRPC.swift`: Collection queries and counts
- `Query+gRPC.swift`: Query execution
- `QueryPredicate+gRPC.swift`: Converts Swift predicates to Firestore protocol buffers

This separation keeps business logic clean from protocol buffer implementation details.

### Custom Codable Implementation
The library provides custom `FirestoreEncoder` and `FirestoreDecoder` in `Sources/FirestoreAPI/Cadable/`:
- Handles Firestore-specific types: `Timestamp`, `GeoPoint`, `DocumentReference`
- Supports special property wrappers: `@DocumentID`, `@ExplicitNull`, `@ReferencePath`
- Converts between Swift types and Firestore protocol buffer values

### Query System
Queries use a **predicate chain pattern** (`QueryPredicate` enum):
- Predicates are accumulated in an array and composed into composite filters
- Supports field filters, unary filters, and composite filters (AND/OR)
- Special handling for document ID queries vs field queries
- Automatic conversion to Firestore's `StructuredQuery` protocol buffers

### Transaction & Batch Writes
- `Transaction`: Atomic read-then-write operations with automatic retry using exponential backoff
- `WriteBatch`: Batched write operations (no reads)
- Both use the same underlying `WriteData` structure but differ in execution semantics

## Development Commands

### Build & Test
```bash
# Build the package
swift build

# Run all tests
swift test

# Build specific configuration
swift build -c release

# Run specific test
swift test --filter FirestoreEncoderTests
```

### Protocol Buffer Generation
The project uses a googleapis submodule (`goolgeapis/`) to generate Firestore API bindings:

```bash
# Generate proto files (run from project root)
mkdir -p Sources/FirestoreAPI/Proto
cd goolgeapis
protoc \
  ./google/firestore/v1/*.proto \
  ./google/api/field_behavior.proto \
  ./google/api/resource.proto \
  ./google/longrunning/operations.proto \
  ./google/rpc/status.proto \
  ./google/type/latlng.proto \
  --swift_out=../Sources/FirestoreAPI/Proto \
  --grpc-swift_out=../Sources/FirestoreAPI/Proto \
  --swift_opt=Visibility=Public \
  --grpc-swift_opt=Visibility=Public
```

Generated files are in `Sources/FirestoreAPI/Proto/` and should not be manually edited.

### Testing Setup
Tests require a Firebase service account key:
1. Download `ServiceAccount.json` from Firebase Console
2. Place it in `Tests/FirebaseAPITests/` directory (gitignored)
3. The test target includes it as a copied resource

## Key Implementation Patterns

### Access Token Authentication
All Firestore operations require OAuth2 access tokens:
- Implement `AccessTokenProvider` protocol to supply tokens
- Set `firestore.accessTokenProvider` before making requests
- Tokens are passed via gRPC metadata headers: `("authorization", "Bearer <token>")`

### Error Handling & Retry
- `ExponentialBackoff`: Retry logic for transactions (max attempts configurable)
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
4. **Concurrent Safety**: Uses NIO EventLoopGroup with thread count = CPU cores for concurrent operations

## Code Organization

```
Sources/FirestoreAPI/
├── Core types: Firestore, Database, CollectionReference, DocumentReference
├── Query system: Query, QueryPredicate, QuerySnapshot
├── Write operations: WriteBatch, Transaction
├── Codable/: FirestoreEncoder, FirestoreDecoder
├── PropertyWrapper/: @DocumentID, @ExplicitNull, @ReferencePath
├── gPRC/: Protocol buffer conversion extensions
├── Proto/: Generated protobuf files (google.firestore.v1.*)
└── Support: FirestoreLogger, FirestoreRetry, ExponentialBackoff
```

## Platform Support
- iOS 15+
- macOS 10.15+
- Uses Swift 5.10+ (see Package.swift)
