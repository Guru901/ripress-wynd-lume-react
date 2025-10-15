#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if command -v pnpm >/dev/null 2>&1; then
  PKG_MGR="pnpm"
else
  PKG_MGR="npm"
fi

echo "Building frontend..."
if [ ! -d "frontend/node_modules" ]; then
  (cd frontend && $PKG_MGR install --silent)
fi
(cd frontend && $PKG_MGR run build)

echo "Building Rust binary..."
cargo build --release

echo "Build complete. Frontend in dist/, binary in target/release/"
echo "Run scripts/start.sh to start the server"

