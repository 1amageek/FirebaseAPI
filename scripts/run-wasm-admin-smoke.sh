#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WASM_SDK="${WASM_SDK:-swift-6.3.1-RELEASE_wasm}"
SMOKE_DIR="${SMOKE_DIR:-$ROOT_DIR/.build/wasm-admin-smoke}"

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

if [[ "${CLEAN_WASM_SMOKE:-0}" == "1" ]]; then
  rm -rf "$SMOKE_DIR"
fi
mkdir -p "$SMOKE_DIR/Sources/FirebaseAPIWasmSmoke"

cat >"$SMOKE_DIR/Package.swift" <<SWIFT
// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "FirebaseAPIWasmSmoke",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "$ROOT_DIR"),
        .package(url: "https://github.com/1amageek/grpc-swift-2.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "FirebaseAPIWasmSmoke",
            dependencies: [
                .product(name: "FirestoreAdminServer", package: "FirebaseAPI"),
                .product(name: "GRPCCore", package: "grpc-swift-2")
            ]
        )
    ]
)
SWIFT

cat >"$SMOKE_DIR/Sources/FirebaseAPIWasmSmoke/FirebaseAPIWasmSmoke.swift" <<'SWIFT'
import FirestoreAdminServer
import GRPCCore

@main
struct FirebaseAPIWasmSmoke {
    static func main() async throws {
        let firestore = FirestoreAdmin(
            projectId: "wasm-project",
            transport: SmokeTransport(),
            settings: FirestoreSettings.hostManagedAuthentication(logLevel: .warning)
        )

        let reference = try firestore.document("users/alice")
        let batch = firestore.batch()
        batch.setData(["name": "Ada"], forDocument: reference)

        do {
            try await batch.commit()
            await firestore.shutdown()
            throw SmokeError.expectedTransportFailure
        } catch FirestoreError.rpcError(let error) where error.code == .unimplemented {
            await firestore.shutdown()
        } catch {
            await firestore.shutdown()
            throw error
        }

        print("FirestoreAdmin WASM host transport smoke passed: users users/alice")
    }
}

enum SmokeError: Error {
    case expectedTransportFailure
}

struct SmokeTransport: ClientTransport {
    typealias Bytes = [UInt8]

    private let state = SmokeTransportState()

    var retryThrottle: RetryThrottle? {
        nil
    }

    func connect() async throws {
        await state.waitUntilShutdown()
    }

    func withStream<T: Sendable>(
        descriptor: MethodDescriptor,
        options: CallOptions,
        _ closure: (RPCStream<Inbound, Outbound>, ClientContext) async throws -> T
    ) async throws -> T {
        throw RPCError(code: .unimplemented, message: "Smoke transport reached host-managed authentication boundary")
    }

    func config(forMethod descriptor: MethodDescriptor) -> MethodConfig? {
        nil
    }

    func beginGracefulShutdown() {
        Task {
            await state.beginShutdown()
        }
    }
}

actor SmokeTransportState {
    private var shuttingDown = false
    private var shutdownWaiters: [CheckedContinuation<Void, Never>] = []

    func waitUntilShutdown() async {
        if shuttingDown {
            return
        }

        await withCheckedContinuation { continuation in
            shutdownWaiters.append(continuation)
        }
    }

    func beginShutdown() {
        guard !shuttingDown else {
            return
        }
        shuttingDown = true
        let waiters = shutdownWaiters
        shutdownWaiters.removeAll()
        for waiter in waiters {
            waiter.resume()
        }
    }
}
SWIFT

cd "$SMOKE_DIR"
printf 'Running FirestoreAdmin WASM host transport smoke...\n'
set +e
set -o pipefail
"${SWIFT_COMMAND[@]}" run --quiet --disable-sandbox --disable-index-store --swift-sdk "$WASM_SDK" FirebaseAPIWasmSmoke 2>&1 \
  | grep -v '^"poll_oneoff" not implemented yet$'
status=${PIPESTATUS[0]}
set +o pipefail
set -e
exit "$status"
