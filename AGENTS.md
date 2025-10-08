# Repository Guidelines

## Project Structure & Module Organization
FirebaseAPI is shipped as a Swift package. Core code lives in `Sources/FirestoreAPI`, split by role: `Cadable/` holds custom encoders and decoders, `gPRC/` wraps Firestore gRPC calls, and `PropertyWrapper/` defines helpers like `@DocumentID`. Generated protobuf stubs belong in `Sources/FirestoreAPI/Proto` and should remain auto-generated. Tests mirror the module under `Tests/FirebaseAPITests`, with files grouped by feature. The upstream protobuf definitions are vendored under the `goolgeapis/` submodule; sync it before rebuilding generated code.

## Build, Test, and Development Commands
- `swift build --configuration debug` compiles the `FirestoreAPI` target and surfaces dependency issues early.
- `swift test --parallel` runs the XCTest suite; append `--filter FirestoreEncoderTests` to iterate on a specific case.
- Regenerate Firestore stubs after updating `goolgeapis`:
```bash
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

## Coding Style & Naming Conventions
Follow the Swift API Design Guidelines: 4-space indentation, `UpperCamelCase` for types, and `lowerCamelCase` for members. Favor `struct` or `final class` to match existing patterns, and keep public API documented with concise doc comments. Extensions should stay feature-scoped (see `Firestore+Transaction.swift` for the pattern). Avoid editing generated files or mixing networking logic outside the `gPRC/` folder.

## Testing Guidelines
Tests are written with `XCTestCase` and live in `Tests/FirebaseAPITests`. Name new suites `<Feature>Tests` and individual methods `test<Behavior>` so they auto-discover. Run `swift test --parallel` before submitting and add coverage for both Codable paths (`Cadable/`) and gRPC surfaces where possible. Integration checks that need Firebase credentials should load `ServiceAccount.json` outside source control; keep secrets in your keychain and pass paths via environment variables when running tests locally.

## Commit & Pull Request Guidelines
Recent commits use short, imperative subjects (e.g., "Remove unused DocumentMask in gRPC requests"). Continue that format, keep the subject under 72 characters, and describe reasoning in the body when non-obvious. Pull requests should include: purpose summary, notes on regenerated protobufs, linked issues or tickets, verification steps (`swift test` output), and screenshots only when UI-affecting. Mark generated diffs clearly so reviewers can focus on hand-written changes.

## Security & Configuration Tips
Do not commit credentials or generated proto outputs that include secrets. Store `ServiceAccount.json` outside the repo and reference it through environment variables like `FIREBASE_SERVICE_ACCOUNT`. When rotating credentials, update local keychains and re-run the regeneration command to ensure compiled clients stay in sync with current Firestore schemas.
