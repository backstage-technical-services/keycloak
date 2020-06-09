#!/usr/bin/env bash
set -eo pipefail

image="${1}"

if [[ -z "${image}" ]]; then
    echo "No image specified."
    exit 1
fi

version=$(< ${image}/version.txt)

if [[ -z "${version}" ]]; then
    echo "No version specified."
    exit 2
fi

imageRegistry="docker.pkg.github.com/${GITHUB_REPOSITORY}/${image}:${version}"
echo "Pushing bts-${image}:${version} to ${imageRegistry}"

cat .github_token | docker login docker.pkg.github.com -u $GITHUB_ACTOR --password-stdin
docker tag "bts-${image}:${version}" "${imageRegistry}"
docker push "${imageRegistry}" 1> /dev/null
