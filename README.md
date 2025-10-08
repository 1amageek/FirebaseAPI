# FirebaseAPI

FirebaseAPI for Swift is a Swift package that provides a simple interface to interact with Firebase services using gRPC.

This repository includes the [googleapis](https://github.com/googleapis/googleapis) repository as a submodule, which is used to generate the API client code for Firebase.

## Features

- ✅ **Firestore API**: Full support for Firestore operations (CRUD, queries, transactions, batches)
- ✅ **Generic Transport**: Support for any `ClientTransport` implementation from grpc-swift-2
- ✅ **Swift 6 Ready**: Full concurrency support with `async/await` and `Sendable`
- ✅ **Type-safe Encoding/Decoding**: FirestoreEncoder and FirestoreDecoder for seamless Swift type conversion
- ✅ **Property Wrappers**: `@DocumentID`, `@ReferencePath`, `@ExplicitNull` for Firestore-specific behaviors
- ✅ **Retry Strategy**: Built-in retry handling with exponential backoff

## Requirements

- Swift 6.2+
- macOS 15.0+ / iOS 18.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+

## Installation

Add FirebaseAPI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/FirebaseAPI.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FirestoreAPI", package: "FirebaseAPI")
    ]
)
```

## Usage

### Initialize Firestore

```swift
import FirestoreAPI
import GRPCHTTP2TransportNIOPosix // or your preferred transport

// Create a transport (example using HTTP/2 with NIO)
let transport = HTTP2ClientTransport.Posix(
    target: .ipv4(host: "firestore.googleapis.com", port: 443),
    config: .defaults(transportSecurity: .tls)
)

// Initialize Firestore with generic transport
let firestore = Firestore(
    projectId: "your-project-id",
    transport: transport,
    accessTokenProvider: yourAccessTokenProvider
)
```

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
let userRef = firestore.collection("users").document("user123")
try await userRef.setData([
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": Timestamp.now()
], firestore: firestore)

// Or use Codable
let user = User(id: "user123", name: "John Doe", email: "john@example.com", createdAt: .now())
try await userRef.setData(user, firestore: firestore)

// Read a document
let snapshot = try await userRef.getDocument(firestore: firestore)
if let data = snapshot.data() {
    print("User data: \(data)")
}

// Or decode to Codable
let user: User? = try await userRef.getDocument(type: User.self, firestore: firestore)

// Update a document
try await userRef.updateData(["name": "Jane Doe"], firestore: firestore)

// Delete a document
try await userRef.delete(firestore: firestore)
```

### Queries

```swift
// Simple query
let usersRef = firestore.collection("users")
let snapshot = try await usersRef
    .where("age" >= 18)
    .where("city" == "Tokyo")
    .orderBy("name", descending: false)
    .limit(10)
    .getDocuments(firestore: firestore)

for doc in snapshot.documents {
    print(doc.data())
}

// Query with Codable
let users: [User] = try await usersRef
    .where("age" >= 18)
    .getDocuments(type: User.self, firestore: firestore)
```

### Transactions

```swift
try await firestore.runTransaction { transaction in
    // Read documents
    let userDoc = firestore.document("users/user123")
    let snapshot = try await transaction.get(documentReference: userDoc)

    guard let balance = snapshot.data()?["balance"] as? Int else {
        throw FirestoreError.notFound
    }

    // Write operations
    transaction.updateData(["balance": balance - 100], forDocument: userDoc)

    return balance - 100
}
```

### Batch Writes

```swift
let batch = firestore.batch()

let user1 = firestore.document("users/user1")
let user2 = firestore.document("users/user2")

batch.setData(["name": "Alice"], forDocument: user1)
batch.updateData(["lastLogin": Timestamp.now()], forDocument: user2)
batch.deleteDocument(document: firestore.document("users/user3"))

try await batch.commit()
```

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

### Generic Transport Design

FirebaseAPI uses a generic `Transport` parameter that conforms to `ClientTransport` from grpc-swift-2. This design allows:

- **Flexibility**: Use any transport implementation (HTTP/2, NIO-based, custom)
- **Type Safety**: Transport type is known at compile time for optimal performance
- **Testability**: Easy to mock transport for unit tests

```swift
public final class Firestore<Transport: ClientTransport>: Sendable {
    internal let transport: Transport
    // ...
}
```

### Why Generic Instead of Protocol?

The library uses `Firestore<Transport: ClientTransport>` instead of `any ClientTransport` because:

1. **gRPC Client Requirements**: `GRPCClient<Transport>` requires a concrete type parameter
2. **Swift Type System**: Existential types (`any Protocol`) cannot conform to protocols with `Self` requirements
3. **Performance**: Generic types are resolved at compile time, avoiding runtime overhead

## Development

### Prerequisites

To develop this library, you need:
1. Swift 6.2+
2. Protocol Buffer compiler (`protoc`)
3. gRPC Swift plugins

### Generating Proto Files

This repository includes the googleapis as a submodule. To regenerate the Firestore proto files:

```bash
mkdir -p Sources/FirestoreAPI/Proto
cd googleapis
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

### Running Tests

The test suite uses **Swift Testing** framework (not XCTest):

```bash
swift test
```

All 59 tests should pass:
- Reference Path Tests: 9 tests
- Query Predicate Tests: 6 tests
- Firestore Encoder Tests: 21 tests
- Firestore Decoder Tests: 23 tests

### Test Coverage

- ✅ Firestore Encoder/Decoder for all supported types
- ✅ Document reference path generation
- ✅ Query predicates and operators
- ✅ Property wrappers (@DocumentID, @ReferencePath, @ExplicitNull)
- ✅ Mock transport for testing without network calls

## Dependencies

- [grpc-swift-2](https://github.com/grpc/grpc-swift-2): gRPC core and protocols
- [grpc-swift-protobuf](https://github.com/grpc/grpc-swift-protobuf): Protobuf serialization
- [swift-protobuf](https://github.com/apple/swift-protobuf): Protocol Buffer runtime
- [swift-log](https://github.com/apple/swift-log): Logging infrastructure

## Migration from grpc-swift 1.x

This library has been migrated to **grpc-swift-2.x**. Key changes:

- `HPACKHeaders` → `Metadata`
- `ClientCall` → `ClientRequest` with new API
- Direct `GRPCClient` creation instead of connection pooling
- Streaming APIs are currently commented out (TODO: implement with new API)

## Known Limitations

- 🚧 Streaming APIs (`listen()`, `streamDocuments()`) are not yet implemented for grpc-swift-2
- These are marked with `// TODO: Fix streaming API for grpc-swift-2` in the codebase

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
