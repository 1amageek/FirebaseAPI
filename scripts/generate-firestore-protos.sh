#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLD_PROTO_DIR="$ROOT_DIR/Sources/FirestoreAPI/Proto"
PROTO_MESSAGE_DIR="$ROOT_DIR/Sources/FirestoreProtobuf/Proto"
PROTO_GRPC_DIR="$ROOT_DIR/Sources/FirestoreGRPCStubs/Proto"

cd "$ROOT_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/module-cache"

mkdir -p "$PROTO_MESSAGE_DIR" "$PROTO_GRPC_DIR"

swift build --product protoc-gen-swift
swift build --product protoc-gen-grpc-swift-2

BIN_DIR="$(swift build --show-bin-path)"

rm -rf "$OLD_PROTO_DIR" "$PROTO_MESSAGE_DIR" "$PROTO_GRPC_DIR"
mkdir -p "$PROTO_MESSAGE_DIR" "$PROTO_GRPC_DIR"

cd "$ROOT_DIR/goolgeapis"
protoc \
  -I . \
  ./google/firestore/v1/*.proto \
  ./google/api/field_behavior.proto \
  ./google/api/resource.proto \
  ./google/longrunning/operations.proto \
  ./google/rpc/status.proto \
  ./google/type/latlng.proto \
  --plugin=protoc-gen-swift="$BIN_DIR/protoc-gen-swift" \
  --swift_out="$PROTO_MESSAGE_DIR" \
  --swift_opt=Visibility=Package \
  --swift_opt=UseAccessLevelOnImports=true

protoc \
  -I . \
  ./google/firestore/v1/*.proto \
  ./google/api/field_behavior.proto \
  ./google/api/resource.proto \
  ./google/longrunning/operations.proto \
  ./google/rpc/status.proto \
  ./google/type/latlng.proto \
  --plugin=protoc-gen-grpc-swift-2="$BIN_DIR/protoc-gen-grpc-swift-2" \
  --grpc-swift-2_out="$PROTO_GRPC_DIR" \
  --grpc-swift-2_opt=Visibility=Package \
  --grpc-swift-2_opt=UseAccessLevelOnImports=true \
  --grpc-swift-2_opt=ExtraModuleImports=FirestoreProtobuf

find "$PROTO_GRPC_DIR" -name '*.grpc.swift' -print0 | xargs -0 perl -0pi -e '
  s/\n\@available\([^\n]+\)\n(?:(?:internal|package) )?extension GRPCCore\.ServiceDescriptor \{\n    \/\/\/ Service descriptor for the "[^"]+" service\.\n    (?:(?:internal|package) )?static let google_[A-Za-z0-9_]+ = GRPCCore\.ServiceDescriptor\(fullyQualifiedService: "[^"]+"\)\n\}\n//g;
'
