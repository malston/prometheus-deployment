#!/usr/bin/env bash

function main() {
  local release="${1}"
  local version="${2}"
  
  printf "Fetch %s of %s chart\n" "${version}" "${release}"

  helm fetch \
    --repo https://kubernetes-charts.storage.googleapis.com \
    --untar \
    --untardir ./charts \
    --version "${version}" \
    "${release}"
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

release="${1:-$RELEASE}"
version="${2:-$VERSION}"

if [[ -z "${release}" ]]; then
  echo "Release is required"
  exit 1
fi

if [[ -z "${version}" ]]; then
  echo "Version is required"
  exit 1
fi

main "${release}" "${version}"
