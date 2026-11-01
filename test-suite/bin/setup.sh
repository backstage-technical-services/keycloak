#!/usr/bin/env bash
# Bring up the compose stack, wait for health, bootstrap Keycloak, then apply every terraform/realms/* root against it.
# Does not run Vitest — from repo root: `yarn --cwd test-suite test`

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
export COMPOSE_FILE="$REPO_ROOT/docker-compose.yaml:$REPO_ROOT/test-suite/docker-compose.yaml"

readonly TF_OVERRIDE="$REPO_ROOT/test-suite/terraform/test_override.tf"
readonly TF_STATE_DIR="$REPO_ROOT/test-suite/.terraform"

cleanup() {
  local -r ec=$?
  rm -f terraform/realms/*/test_override.tf
  if (( ec != 0 )); then
    echo ":: Cleaning up" >&2
    docker compose down -v || true
  fi
  exit "$ec"
}
trap cleanup EXIT

echo ":: Building and running the stack"
docker compose build keycloak
docker compose up -d
test-suite/bin/wait_until_healthy.sh

echo ":: Bootstrapping Keycloak"
test-suite/init/keycloak/bootstrap.sh

mkdir -p "$TF_STATE_DIR"
rm -f "$TF_STATE_DIR"/*.tfstate*

for root in terraform/realms/*/; do
  realm="$(basename "$root")"
  echo ":: Applying realm: ${realm}"

  cp "$TF_OVERRIDE" "${root}test_override.tf"
  export TF_DATA_DIR="$TF_STATE_DIR/$realm"
  terraform -chdir="$root" init \
    -reconfigure \
    -input=false \
    -backend-config="path=$TF_STATE_DIR/$realm.tfstate"
  terraform -chdir="$root" apply \
    -auto-approve \
    -input=false
  rm "${root}test_override.tf"
done

echo ":: Setup complete"
echo "Run tests with: yarn --cwd test-suite test"
