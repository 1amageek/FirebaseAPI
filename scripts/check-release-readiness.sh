#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-300}"
XCODE_SCHEME="${XCODE_SCHEME:-FirebaseAPI-Package}"
XCODE_DESTINATION="${XCODE_DESTINATION:-platform=macOS}"

assert_no_matches() {
  local description="$1"
  shift

  local output
  set +e
  output="$("$@" 2>&1)"
  local status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    printf 'Release readiness check failed: %s\n' "$description" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi

  if [[ "$status" -ne 1 ]]; then
    printf 'Release readiness check errored: %s\n' "$description" >&2
    printf '%s\n' "$output" >&2
    exit "$status"
  fi
}

add_unique_modulemap_argument() {
  local modulemap="$1"
  local seen_modules="$2"

  local module
  module="$(sed -nE 's/^[[:space:]]*(framework[[:space:]]+)?module[[:space:]]+([^[:space:]\{]+).*/\2/p' "$modulemap" | head -n 1)"
  [[ -n "$module" ]] || return 0

  if grep -Fxq "$module" "$seen_modules"; then
    return 0
  fi

  printf '%s\n' "$module" >> "$seen_modules"
  printf '%s\n' "-Xcc"
  printf '%s\n' "-fmodule-map-file=$modulemap"
}

emit_public_product_symbol_graphs() {
  local symbol_graph_dir=".build/out/symbolgraph"
  local build_products_dir
  local sdk_path
  local target_triple
  local seen_modules
  local modulemap_args=()
  local include_args=()
  local module_search_args=()

  swift build --quiet --product FirestoreAPI >/dev/null
  swift build --quiet --product FirestoreAdminServer >/dev/null
  swift build --quiet --product FirestoreMongoCore >/dev/null

  build_products_dir="$(swift build --show-bin-path)"
  sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
  target_triple="$(swift -print-target-info | /usr/bin/python3 -c 'import json, sys; print(json.load(sys.stdin)["target"]["triple"])')"
  seen_modules="$(mktemp)"

  rm -rf "$symbol_graph_dir"
  mkdir -p "$symbol_graph_dir"

  module_search_args+=("-I" "$build_products_dir")
  if [[ -d "$build_products_dir/Modules" ]]; then
    module_search_args+=("-I" "$build_products_dir/Modules")
  fi

  while IFS= read -r module_map_dir; do
    module_search_args+=("-I" "$module_map_dir")
    while IFS= read -r modulemap; do
      while IFS= read -r argument; do
        modulemap_args+=("$argument")
      done < <(add_unique_modulemap_argument "$modulemap" "$seen_modules")
    done < <(find "$module_map_dir" -maxdepth 1 -name '*.modulemap' -type f | sort)
  done < <(find .build -path '*GeneratedModuleMaps' -type d ! -path '*webassembly*' ! -path '*wasm32*' 2>/dev/null | sort)

  for source_root in ../networking .build/checkouts; do
    [[ -d "$source_root" ]] || continue

    while IFS= read -r include_dir; do
      include_args+=("-Xcc" "-I$include_dir")
    done < <(find "$source_root" -path '*/Sources/*/include' -type d 2>/dev/null | sort -u)

    while IFS= read -r modulemap; do
      while IFS= read -r argument; do
        modulemap_args+=("$argument")
      done < <(add_unique_modulemap_argument "$modulemap" "$seen_modules")
    done < <(find "$source_root" -path '*/Sources/*/include/module.modulemap' -type f 2>/dev/null | sort)
  done

  rm -f "$seen_modules"

  for module in FirestoreAPI FirestoreAdminServer FirestoreMongoCore; do
    swift symbolgraph-extract \
      -module-name "$module" \
      "${module_search_args[@]}" \
      -target "$target_triple" \
      -sdk "$sdk_path" \
      "${include_args[@]}" \
      "${modulemap_args[@]}" \
      -minimum-access-level public \
      -skip-synthesized-members \
      -output-dir "$symbol_graph_dir"
  done

  if ! find "$symbol_graph_dir" -maxdepth 1 -name 'Firestore*.symbols.json' -type f | grep -q .; then
    printf 'Release readiness check failed: public Firestore symbol graphs were not generated\n' >&2
    exit 1
  fi
}

printf 'Checking whitespace-sensitive diffs...\n'
git diff --check

printf 'Checking legacy implementation names...\n'
assert_no_matches \
  "legacy gPRC typo and obsolete Admin facade type names must not return" \
  rg -n "gPRC|FirestoreAdminFacade|AdminFacade" Sources docs README.md Package.swift -S

printf 'Checking RPC compiler boundaries...\n'
assert_no_matches \
  "RPC compiler/reducer files must not depend on grpc-swift transport types" \
  rg -n "import GRPCCore|RPCError|ClientTransport|StreamingClientRequest|StreamingClientResponse|GRPCNIOTransport" Sources/FirestoreRPC -S

printf 'Checking gRPC request wrapper ownership...\n'
assert_no_matches \
  "finite ClientRequest wrappers must stay in FirestoreGRPCRuntime+FiniteRequest.swift" \
  rg -n '(^|[^A-Za-z])ClientRequest[<(]' Sources/FirestoreGRPCTransport --glob '!**/FirestoreGRPCRuntime+FiniteRequest.swift' -S
assert_no_matches \
  "streaming ClientRequest wrappers must stay in FirestoreListenStreamExecutor.swift" \
  rg -n 'StreamingClientRequest[<(]' Sources/FirestoreGRPCTransport --glob '!**/FirestoreListenStreamExecutor.swift' -S

printf 'Checking generated gRPC client call ownership...\n'
assert_no_matches \
  "generated Firestore client calls must stay in FirestoreGRPCRuntime operation wrappers" \
  rg -n 'client\.(getDocument|listDocuments|updateDocument|deleteDocument|batchGetDocuments|beginTransaction|commit|rollback|runQuery|executePipeline|runAggregationQuery|partitionQuery|write|listen|listCollectionIds|batchWrite|createDocument)\(' Sources --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Aggregation.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+BatchWrite.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+CollectionOperations.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+DocumentOperations.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Listen.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Pipeline.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+QueryOperations.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Read.swift' --glob '!Sources/FirestoreGRPCTransport/FirestoreGRPCRuntime+Transaction.swift' -S
assert_no_matches \
  "low-level write generated client calls must not be used by hand-written transport code" \
  rg -n 'client\.(createDocument|updateDocument|deleteDocument|write)\(' Sources/FirestoreGRPCTransport -S

printf 'Checking handwritten source safety patterns...\n'
assert_no_matches \
  "hand-written source must not use forbidden Swift patterns" \
  rg -n "as!|try!|try\\?|EventLoopFuture|DispatchQueue|@unchecked Sendable|nonisolated\\(unsafe\\)" Sources --glob '!Sources/FirestoreAPI/Proto/**' --glob '!Sources/FirestoreProtobuf/Proto/**' --glob '!Sources/FirestoreGRPCStubs/Proto/**' -S

printf 'Checking protobuf type containment...\n'
assert_no_matches \
  "protobuf implementation types must stay out of core public source" \
  rg -n "Google_Firestore|Google_Protobuf|SwiftProtobuf" Sources/FirestoreCore Sources/FirestoreRuntimeConfig Sources/FirestorePipeline Sources/FirestoreRuntimeSupport Sources/FirestoreCodable Sources/FirestoreGeoQuery Sources/FirestoreAdmin Sources/FirestoreAdminCodable Sources/FirestoreAPI -S

printf 'Checking runtime configuration boundaries...\n'
assert_no_matches \
  "FirestoreCore must not own server runtime configuration types" \
  rg -n "FirestoreSettings|FirestoreRetryStrategy|FirestoreRetryHandler|FirestoreRetryable|FirestoreLogLevel|FirestoreAuthenticationMode" Sources/FirestoreCore -S
assert_no_matches \
  "FirestoreRuntimeConfig must not depend on transport, auth implementations, RPC compilers, protobuf, Pipeline, or logging" \
  rg -n "import FirestoreAuth|import FirestoreAuthCore|import FirestoreGRPCTransport|import FirestoreGRPCStubs|import FirestoreProtobuf|import FirestoreRPC|import FirestorePipelineRPC|import FirestorePipeline|import GRPCCore|import GRPCProtobuf|import GRPCNIOTransport|import SwiftProtobuf|import Logging|Google_Firestore|Google_Protobuf|ClientTransport|RPCError|PipelineCompiler|QueryCompiler|DocumentRequestCompiler|WriteCompiler" Sources/FirestoreRuntimeConfig -S

printf 'Checking Native/Mongo-compatible responsibility split...\n'
assert_no_matches \
  "Mongo-compatible constructs must stay out of Native Firestore source" \
  rg -n 'Mongo|BSON|\$near|2dsphere' Sources/FirestoreCore Sources/FirestoreRuntimeConfig Sources/FirestorePipeline Sources/FirestoreRuntimeSupport Sources/FirestoreCodable Sources/FirestoreGeoQuery Sources/FirestoreRPC Sources/FirestoreGRPCTransport Sources/FirestoreAdmin Sources/FirestoreAdminCodable Sources/FirestoreAPI --glob '!Sources/FirestoreAPI/FirestoreMongoCoreExports.swift' -S

printf 'Checking Mongo-compatible core boundaries...\n'
assert_no_matches \
  "FirestoreMongoCore must not depend on Native RPC, Pipeline RPC, Native GeoQuery, protobuf, or grpc-swift transport" \
  rg -n "import FirestoreGeoQuery|import FirestorePipeline|import FirestoreRPC|import FirestorePipelineRPC|import FirestoreProtobuf|import FirestoreGRPCStubs|import FirestoreGRPCTransport|import GRPCCore|import GRPCProtobuf|import GRPCNIOTransport|Google_Firestore|Google_Protobuf|SwiftProtobuf|ClientTransport|RPCError|StructuredQuery|ExecutePipeline|QueryCompiler|QueryPredicateFilterCompiler|PipelineCompiler" Sources/FirestoreMongoCore -S

printf 'Checking public symbol graph surface...\n'
emit_public_product_symbol_graphs >/dev/null
assert_no_matches \
  "public symbol graph must not expose protobuf, gRPC transport, or internal planning symbols" \
  rg -n "Google_Firestore|Google_Protobuf|SwiftProtobuf|GRPCCore|GRPCClient|ClientTransport|ClientRequest|ClientResponse|RPCError|FirestoreGRPCRuntime|FirestoreRPCExecutor|FirestoreListenStreamExecutor|FirestoreRuntime\\\"|FirestoreTransactionRuntime\\\"|DocumentRequestCompiler|TransactionRequestCompiler|QueryCompiler|WriteCompiler|BatchWriteCompiler|PartitionQueryCompiler|PipelineCompiler|ReadResponseMapper|PipelineResponseMapper|QueryPredicateFilterCompiler|ListenTargetBuilder|ListenRequestStreamController|DocumentListenState|QueryListenState|ListenStreamCoordinator|WriteData|QueryPredicate|AggregateField\\.Operation|AggregateField\",\"operation|AggregateField\",\"fieldPath|AggregateField\",\"alias|PipelineValue\\.Storage|PipelineValue\\.storage|PipelineValue\\.pipeline\\(|PipelineExplainStats\",\"rawTypeURL|PipelineExplainStats\",\"rawData|PipelineExplainStats\",\"init\\(outputFormat:text:json:rawTypeURL:rawData:\\)|ServiceAccountCredentials\",\"privateKey|ServiceAccountCredentials\",\"privateKeyId|ServiceAccountCredentials\",\"tokenURI|where\\(field|where\\(isEqualTo|where\\(isNotEqualTo|where\\(isLessThan|where\\(isLessThanOrEqualTo|where\\(isGreaterThan|where\\(isGreaterThanOrEqualTo|where\\(arrayContains|where\\(arrayContainsAny|where\\(in:|where\\(notIn:|clearPersistence|enableNetwork|disableNetwork|waitForPendingWrites|ListenerRegistration|snapshotsInSync|addSnapshotsInSyncListener|PersistentCache|MemoryCache|LocalCache|cacheSettings|terminate\\(" .build/out/symbolgraph -S

printf 'Checking live Firestore smoke diagnostics...\n'
bash -n scripts/run-live-firestore-smoke.sh
FIRESTORE_LIVE_SMOKE=1 FIRESTORE_LIVE_DIAGNOSTICS_ONLY=1 \
  bash scripts/run-live-firestore-smoke.sh >/dev/null

printf 'Running Swift test suite...\n'
perl -e 'alarm shift; exec @ARGV' "$TEST_TIMEOUT_SECONDS" \
  xcodebuild -quiet -scheme "$XCODE_SCHEME" -destination "$XCODE_DESTINATION" test

printf 'Release readiness checks passed.\n'
