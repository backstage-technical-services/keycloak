#!/usr/bin/env bash
set -eo pipefail
image_versions=$(cat versions.json)

docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

for image in $(jq -r 'keys[]' versions.json); do
  version=$(echo "${image_versions}" | jq -r ".${image}")
  image_registry="${CI_REGISTRY_IMAGE}/${image}:${version}"

  echo "Pushing bts-${image}:${version} to ${image_registry}"
  docker tag "bts-${image}:${version}" "${image_registry}"
  docker push "${image_registry}" 1> /dev/null
done
