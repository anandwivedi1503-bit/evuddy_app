#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

PORT=8080
if curl -sf "http://127.0.0.1:${PORT}/index.html" >/dev/null 2>&1; then
  exit 0
fi

for _ in $(seq 1 60); do
  if command -v flutter >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

command -v flutter >/dev/null

exec flutter run -d web-server --web-hostname=0.0.0.0 --web-port="${PORT}"
