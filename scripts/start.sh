#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Ensure dist exists
if [ ! -d "dist" ]; then
  echo "dist/ not found. Run scripts/build.sh first." >&2
  exit 1
fi

BIN="${REPO_ROOT}/target/release/ripress-wynd-lume-react-minimal-demo"
if [ ! -x "$BIN" ]; then
  echo "Release binary not found at $BIN. Run scripts/build.sh first." >&2
  exit 1
fi

echo "Starting server from $BIN"
exec "$BIN"