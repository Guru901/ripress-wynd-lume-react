#!/bin/bash
set -euo pipefail

# Move to repo root
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Prefer pnpm, fallback to npm
if command -v pnpm >/dev/null 2>&1; then
  PKG_MGR="pnpm"
else
  PKG_MGR="npm"
fi

# Ensure frontend deps installed
if [ ! -d "frontend/node_modules" ]; then
  (cd frontend && $PKG_MGR install --silent)
fi

# Logs directory (repo-local), fallback to /tmp if not writable
LOG_DIR="${REPO_ROOT}/.logs"
if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
  LOG_DIR="/tmp/ripress-lume-react-logs-$USER"
  mkdir -p "$LOG_DIR"
fi

# Start frontend dev server
FRONTEND_LOG="$LOG_DIR/frontend-dev.log"
FRONTEND_PID=""
(
  cd frontend || exit 1
  nohup $PKG_MGR run dev > "$FRONTEND_LOG" 2>&1 &
  echo $! > "$LOG_DIR/frontend.pid"
) || true
if [ -f "$LOG_DIR/frontend.pid" ]; then
  FRONTEND_PID=$(cat "$LOG_DIR/frontend.pid" 2>/dev/null || echo "")
fi
echo "Started frontend dev server. Logs: $FRONTEND_LOG"

RUST_PID=""

# Check if port 3000 or process already in use, to avoid duplicate Rust servers
PORT_IN_USE=false
PROCESS_RUNNING=false

if command -v lsof >/dev/null 2>&1 && lsof -i :3000 -sTCP:LISTEN >/dev/null 2>&1; then
  PORT_IN_USE=true
elif command -v nc >/dev/null 2>&1 && nc -z localhost 3000 >/dev/null 2>&1; then
  PORT_IN_USE=true
fi

if command -v pgrep >/dev/null 2>&1 && pgrep -f "ripress-wynd-lume-react-minimal-demo" >/dev/null 2>&1; then
  PROCESS_RUNNING=true
fi


if [ "$PORT_IN_USE" = true ] || [ "$PROCESS_RUNNING" = true ]; then
  echo "Rust server appears to be running already (port or process detected). Skipping Rust startup."
else
  # Start Rust server (cargo run)
  RUST_LOG="$LOG_DIR/rust-dev.log"
  (
    cd "$REPO_ROOT" || exit 1
    nohup cargo run > "$RUST_LOG" 2>&1 &
    echo $! > "$LOG_DIR/rust.pid"
  ) || true
  if [ -f "$LOG_DIR/rust.pid" ]; then
    RUST_PID=$(cat "$LOG_DIR/rust.pid" 2>/dev/null || echo "")
  fi
  echo "Started Rust server. Logs: $RUST_LOG"
fi

cleanup() {
  echo "Stopping dev processes..."
  if [ -n "${FRONTEND_PID}" ] && kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
    kill "$FRONTEND_PID" >/dev/null 2>&1 || true
  fi
  if [ -n "${RUST_PID}" ] && kill -0 "$RUST_PID" >/dev/null 2>&1; then
    kill "$RUST_PID" >/dev/null 2>&1 || true
  fi
}

trap cleanup INT TERM EXIT

# Block until interrupted; cleanup trap will handle termination
echo "Press Ctrl+C to stop"
while true; do sleep 1; done