#!/usr/bin/env bash

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

pushd "${image}" &> /dev/null
echo "Building bts-${image}:${version}"
docker build -t "bts-${image}:${version}" --build-arg "VERSION=${version}" . 1> /dev/null
popd &> /dev/null
