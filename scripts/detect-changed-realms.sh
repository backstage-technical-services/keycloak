#!/usr/bin/env bash
# Outputs a JSON array of the realms (terraform/realms/<realm>) affected by the changes between BASE_SHA and HEAD_SHA.
#
#   realms/<realm>.yaml            -> <realm>
#   terraform/realms/<realm>/**    -> <realm>
#   terraform/modules/**, schemas/** -> every realm

set -o errexit
set -o pipefail
set -o nounset

function timestamp() {
  echo "$(date -u +%Y-%m-%dT%H:%I:%S).000Z"
}

function log() {
  echo "$(timestamp) [${1}] ${*:2}" >&2
  if [[ "${1}" == "FATAL" ]]; then
    exit 1
  fi
}

[ -z "${HEAD_SHA:-}" ] && log FATAL "HEAD_SHA environment variable is required"
[ -z "${BASE_SHA:-}" ] && log FATAL "BASE_SHA environment variable is required"

readarray -t all_realms < <(find terraform/realms -mindepth 2 -maxdepth 2 -name .terraform.lock.hcl -exec dirname {} \; | xargs -r -n1 basename | sort)
readarray -t changed_files < <(git diff --no-renames --name-only --merge-base "${BASE_SHA}" "${HEAD_SHA}" --)

declare -A realms=()
for file in "${changed_files[@]}"; do
  case "${file}" in
    terraform/modules/* | schemas/*)
      log INFO "'${file}' affects all realms"
      for realm in "${all_realms[@]}"; do
        realms["${realm}"]=1
      done
      ;;
    realms/*.yaml)
      realm="$(basename "${file}" .yaml)"
      ;;
    terraform/realms/*/*)
      realm="$(echo "${file}" | cut -d/ -f3)"
      ;;
    *)
      log INFO "ignoring changes in '${file}' - this is not a realm config path"
      continue
      ;;
  esac

  if [[ -n "${realm:-}" ]]; then
    if [[ -f "terraform/realms/${realm}/.terraform.lock.hcl" ]]; then
      realms["${realm}"]=1
    else
      log INFO "ignoring changes in '${file}' - terraform/realms/${realm} is not a terraform root"
    fi
    unset realm
  fi
done

configJson="$(printf '%s\n' "${!realms[@]}" | sort | jq --raw-input --slurp --compact-output 'split("\n") | map(select(. != ""))')"

if [[ -n ${GITHUB_OUTPUT+x} ]]; then
  echo "matrix=$configJson" | tee -a "$GITHUB_OUTPUT"
else
  echo "matrix=$configJson"
fi
