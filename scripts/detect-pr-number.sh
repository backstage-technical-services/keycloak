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

[ -z "${COMMIT_SHA:-}" ] && log FATAL "COMMIT_SHA environment variable is required"
[ -z "${GITHUB_REPOSITORY}" ] && log FATAL "GITHUB_REPOSITORY environment variable is required"

pr_number=$(gh api repos/$GITHUB_REPOSITORY/commits/$COMMIT_SHA/pulls --paginate | jq -r '.[0].number')

if [[ "$pr_number" == "null" ]]; then
  log FATAL "No PR associated with commit $COMMIT_SHA"
fi

if [[ -n ${GITHUB_OUTPUT+x} ]]; then
  echo "pr_number=$pr_number" | tee -a $GITHUB_OUTPUT
else
  echo "pr_number=$pr_number"
fi
