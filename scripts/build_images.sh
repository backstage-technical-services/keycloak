#!/usr/bin/env bash
set -eo pipefail
image_versions=$(cat versions.json)

for image in $(echo "${image_versions}" | jq -r 'keys[]'); do
  version=$(echo "${image_versions}" | jq -r ".${image}")
  pushd "${image}" &> /dev/null
  echo "Building bts-${image}:${version}"
  docker build -t "bts-${image}:${version}" --build-arg "VERSION=${version}" . 1> /dev/null
  popd &> /dev/null
done
