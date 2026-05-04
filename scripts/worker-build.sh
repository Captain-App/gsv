#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <crate-dir> [worker-build args...]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRATE_DIR="$ROOT_DIR/$1"
shift

if [ ! -d "$CRATE_DIR" ]; then
  echo "worker-build crate directory not found: $CRATE_DIR" >&2
  exit 1
fi

LOCK_PATH="${TMPDIR:-/tmp}/gsv-worker-build.lock"

run_build() {
  cd "$CRATE_DIR"
  cargo install -q "worker-build@^0.7"
  worker-build "$@" .
}

if command -v flock >/dev/null 2>&1; then
  (
    flock 9
    run_build "$@"
  ) 9>"$LOCK_PATH"
else
  LOCK_DIR="${LOCK_PATH}.d"
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 1
  done
  trap 'rmdir "$LOCK_DIR"' EXIT
  run_build "$@"
fi
