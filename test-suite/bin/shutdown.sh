#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
export COMPOSE_FILE="$REPO_ROOT/docker-compose.yaml:$REPO_ROOT/test-suite/docker-compose.yaml"

echo ":: Cleaning up" >&2
docker compose down -v || true
