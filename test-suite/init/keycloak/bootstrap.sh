#!/usr/bin/env bash
# Post-start Keycloak tweaks for local/CI (run after the container is healthy):
#   1) Set master realm sslRequired=NONE so HTTP clients (e.g. Terraform on the host
#      via Docker-published ports) are not rejected with "HTTPS required".
#   2) Grant the master realm role "admin" to the bootstrap Terraform client's
#      service account (KC_BOOTSTRAP_ADMIN_CLIENT_ID, default "test").
#
# Runs kcadm inside the Keycloak container (one exec so kcadm session/config is shared).
#
# Env (defaults match docker-compose):
#   KEYCLOAK_CONTAINER             Docker container name (default bts-keycloak)
#   KC_INTERNAL_URL                Keycloak URL inside the container (default http://127.0.0.1:8080)
#   KC_BOOTSTRAP_ADMIN_USERNAME    Master admin username (default admin)
#   KC_BOOTSTRAP_ADMIN_PASSWORD    Master admin password (default admin)
#   KC_BOOTSTRAP_ADMIN_CLIENT_ID   Bootstrap client id (default test)

set -euo pipefail

readonly CONTAINER="${KEYCLOAK_CONTAINER:-bts-keycloak}"
readonly KC_INTERNAL_URL="${KC_INTERNAL_URL:-http://127.0.0.1:8080}"
readonly ADMIN_USER="${KC_BOOTSTRAP_ADMIN_USERNAME:-admin}"
readonly ADMIN_PASS="${KC_BOOTSTRAP_ADMIN_PASSWORD:-admin}"
readonly BOOTSTRAP_CLIENT_ID="${KC_BOOTSTRAP_ADMIN_CLIENT_ID:-test}"
readonly SA_USER="service-account-${BOOTSTRAP_CLIENT_ID}"

docker exec \
  -e KCADM_CONFIG="/tmp/kcadm-bootstrap-$$.cfg" \
  -e KC_INTERNAL_URL="$KC_INTERNAL_URL" \
  -e ADMIN_USER="$ADMIN_USER" \
  -e ADMIN_PASS="$ADMIN_PASS" \
  -e SA_USER="$SA_USER" \
  "$CONTAINER" sh -ec '
/opt/keycloak/bin/kcadm.sh config credentials \
  --server "$KC_INTERNAL_URL" \
  --realm master \
  --user "$ADMIN_USER" \
  --password "$ADMIN_PASS" >/dev/null

/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
echo "Master realm sslRequired set to NONE."

if /opt/keycloak/bin/kcadm.sh get-roles -r master --uusername "$SA_USER" --format json 2>/dev/null \
  | jq -e ".[] | select(.name == \"admin\" and (.clientRole // false) == false)" >/dev/null 2>&1
then
  echo "$SA_USER already has realm role admin on master."
else
  /opt/keycloak/bin/kcadm.sh add-roles -r master \
    --uusername "$SA_USER" \
    --rolename admin
  echo "Granted master realm role admin to $SA_USER."
fi
'
