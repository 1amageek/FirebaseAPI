#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WASM_SDK="${WASM_SDK:-swift-6.3.1-RELEASE_wasm}"

export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/wasm-clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/wasm-swiftpm-module-cache"
export XDG_CACHE_HOME="$ROOT_DIR/.build/wasm-xdg-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFTPM_MODULECACHE_OVERRIDE" "$XDG_CACHE_HOME"

if command -v swiftly >/dev/null 2>&1 && swiftly list 2>/dev/null | grep -q "Swift 6.3.1"; then
  SWIFT_COMMAND=(swiftly run swift +6.3.1)
else
  SWIFT_COMMAND=(swift)
fi

if ! "${SWIFT_COMMAND[@]}" sdk list | grep -q "^${WASM_SDK}$"; then
  printf 'Missing Swift Wasm SDK: %s\n' "$WASM_SDK" >&2
  printf 'Install the SDK or set WASM_SDK to an installed Swift SDK identifier.\n' >&2
  exit 1
fi

targets=(
  FirestoreCore
  FirestoreMongo
  FirestoreGeoQuery
  FirestorePipeline
  FirestoreCodable
  FirestoreRuntimeConfig
  FirestoreRuntimeSupport
  FirestoreProtobuf
  FirestoreRPCSupport
  FirestoreRPC
  FirestorePipelineRPC
  FirestoreAdminCore
  FirestoreAdminCodable
  FirestoreAuthCore
  FirestoreAuth
  FirestoreGRPCStubs
  FirestoreGRPCTransport
  FirestoreAdminGRPCBootstrap
  FirestoreAdmin
  FirestoreAPI
)

printf 'Using Swift toolchain for Wasm-compatible Firestore targets: '
"${SWIFT_COMMAND[@]}" --version | head -n 1

printf 'Using Swift SDK: %s\n' "$WASM_SDK"

for target in "${targets[@]}"; do
  printf 'Checking %s...\n' "$target"
  "${SWIFT_COMMAND[@]}" build --disable-sandbox --swift-sdk "$WASM_SDK" --target "$target"
done

if [[ "${RUN_WASM_SMOKE:-1}" == "1" ]]; then
  bash "$ROOT_DIR/scripts/run-wasm-admin-smoke.sh"
fi

printf 'Wasm-compatible Firestore target checks passed.\n'
