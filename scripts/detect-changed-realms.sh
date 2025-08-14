#!/usr/bin/env bash

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

readarray -t changed_paths < <(git diff --no-renames --name-only --merge-base "${BASE_SHA}" "${HEAD_SHA}" -- | xargs -r dirname | sort -u)

# translate any modules into their usages
for i in "${!changed_paths[@]}"; do
    path="${changed_paths[$i]}"
    if [[ "${path}" == terraform/modules/* ]]; then
      module_path_prefix="$(echo "${path}" | sed -E 's#^terraform/(modules/[^\/]+).*#\1#')"

      readarray -t module_usages < <(echo $(grep -r -i -l --include "*.tf" "${module_path_prefix}" terraform/realms || true) | xargs -r dirname | sort -u)

      if [[ ${#module_usages[@]} -gt 0 ]]; then
        log INFO "replacing '${path}' with '${module_usages[@]}'"
        changed_paths+=("${module_usages[@]}")
      else
        log INFO "ignoring changes in '${path}' - component is unused"
      fi

      unset 'changed_paths[i]'
    fi
done

# iterate through all paths and find those which are realm roots
declare -t pruned_changed_paths=()
for path in "${changed_paths[@]}"; do
  if [[ "${path}" == terraform/realms/* ]]; then
    if [[ -f "${path}/.terraform.lock.hcl" ]]; then
      pruned_changed_paths+=("${path}")
    else
      path_parts=($(echo "$path" | tr '/' '\n'))
      path_new=""
      for path_part in "${path_parts[@]}"; do
        path_new="${path_new#/}/$path_part"

        if [[ -f "$path_new/.terraform.lock.hcl" ]]; then
          log INFO "replacing '$path' with '$path_new'"
          pruned_changed_paths+=("$path_new")
          continue 2
        fi
      done

      log INFO "ignoring changes in '${path}' - no .terraform.lock.hcl file"
    fi
  else
      log INFO "ignoring changes in '${path}' - this is not a valid configuration path"
  fi
done

# Remove duplicates
pruned_changed_paths=($(echo "${pruned_changed_paths[@]}" | tr ' ' '\n' | sort -u))

# Convert to JSON-encoded string
configJson="$(jq --null-input '$ARGS.positional' --args -- "${pruned_changed_paths[@]}" | jq --compact-output 'map(. | ltrimstr("terraform/realms/"))')"

if [[ -n ${GITHUB_OUTPUT+x} ]]; then
  echo "matrix=$configJson" | tee -a $GITHUB_OUTPUT
else
  echo "matrix=$configJson"
fi
