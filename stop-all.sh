#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

stop_pid() {
  local pid="$1"
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill -TERM "$pid" >/dev/null 2>&1 || true
  fi
}

for name in eureka candidat canditature job meeting meeting2 notification notification2; do
  if [ -f "logs/$name.pid" ]; then
    stop_pid "$(cat "logs/$name.pid")"
  fi
done

for port in 8761 8081 8082 8083 8084 8085 8093 8094; do
  if command -v lsof >/dev/null 2>&1; then
    for pid in $(lsof -nP -iTCP:$port -sTCP:LISTEN -t 2>/dev/null); do
      stop_pid "$pid"
    done
  fi
done

sleep 2

for port in 8761 8081 8082 8083 8084 8085 8093 8094; do
  if command -v lsof >/dev/null 2>&1; then
    for pid in $(lsof -nP -iTCP:$port -sTCP:LISTEN -t 2>/dev/null); do
      kill -KILL "$pid" >/dev/null 2>&1 || true
    done
  fi
done

echo "Stopped ports 8761, 8081, 8082, 8083, 8084, 8085, 8093 and 8094"
