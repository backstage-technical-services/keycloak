#!/usr/bin/env bash
# Wait until every running Compose container is healthy (or has no healthcheck and is running).
#
# Discovers containers with: docker compose ps --format '{{.Name}}'
#
# Usage:
#   ./test-suite/bin/wait_until_healthy.sh [health_limit_seconds]
#
# Environment:
#   COMPOSE_FILE   Colon-separated compose files (e.g. docker-compose.yaml:docker-compose.tests.yaml)
#                  See https://docs.docker.com/compose/how-tos/multiple-compose-files/
#
# Exit:
#   0 — all listed containers are healthy (or running with no healthcheck)
#   1 — timeout, any container unhealthy, inspect error, or no containers after deadline

set -euo pipefail

readonly health_limit="${1:-300}"
readonly sleep_seconds="${SLEEP_SECONDS:-2}"

if (( health_limit < 1 )); then
  echo "health_limit must be >= 1" >&2
  exit 1
fi

echo "Waiting up to ${health_limit}s for all compose containers to be healthy..."
echo -e "Using compose file: ${COMPOSE_FILE:-<default>}\n"

deadline=$(( $(date +%s) + health_limit ))

while (( $(date +%s) < deadline )); do
  out=$(docker compose ps --format '{{.Name}}' 2>/dev/null | sed '/^$/d' || true)
  if [[ -z "$out" ]]; then names=(); else set -f; names=( $out ); set +f; fi

  if [[ ${#names[@]} -eq 0 ]]; then
    echo "No containers yet; sleeping ${sleep_seconds}s..."
    sleep "$sleep_seconds"
    continue
  fi

  all_ok=true
  for name in "${names[@]}"; do
    if ! running=$(docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null); then
      echo "Could not inspect container: $name" >&2
      all_ok=false
      continue
    fi

    if [[ "$running" != "running" ]]; then
      echo "Container $name state: $running (want running)"
      all_ok=false
      continue
    fi

    health_status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}nohealth{{end}}' "$name" 2>/dev/null || echo "unknown")

    if [[ "$health_status" == "nohealth" ]]; then
      continue
    fi

    if [[ "$health_status" != "healthy" ]]; then
      all_ok=false
    fi
  done

  if $all_ok; then
    echo "All ${#names[@]} container(s) are healthy (or running with no healthcheck)."
    exit 0
  fi

  sleep "$sleep_seconds"
done

echo "Timed out after ${health_limit}s — not all containers became healthy." >&2
docker compose ps -a >&2 || true
docker compose logs --no-color --tail 200 >&2 || true
exit 1
