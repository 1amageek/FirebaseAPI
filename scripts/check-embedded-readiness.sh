#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -n "${EMBEDDED_SWIFT_COMMAND:-}" ]]; then
  read -r -a SWIFT_COMMAND <<<"$EMBEDDED_SWIFT_COMMAND"
elif command -v swiftly >/dev/null 2>&1 && swiftly list 2>/dev/null | grep -q "Swift 6.3.1"; then
  SWIFT_COMMAND=(swiftly run swift +6.3.1)
else
  SWIFT_COMMAND=(swift)
fi

printf 'Using Swift toolchain for Embedded readiness: '
"${SWIFT_COMMAND[@]}" --version | head -n 1

"${SWIFT_COMMAND[@]}" build \
  --target FirestoreEmbedded \
  -Xswiftc -enable-experimental-feature \
  -Xswiftc Embedded
