#!/usr/bin/env bash

function main() {
  local repo="${1}"
  local release="${2}"
  local version="${3}"
  
  printf "Fetch %s of %s chart\n" "${version}" "${release}"

  helm fetch \
    --repo https://kubernetes-charts.storage.googleapis.com \
    --untar \
    --untardir "${repo}/charts" \
    --version "${version}" \
    "${release}"

  cp -r "${repo}/charts" "charts-commit"
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
  version="$(cat version/version)"
  if [[ -z "${version}" ]]; then
    echo "Version is required"
    exit 1
  fi
fi

main "repo" "${release}" "${version}"
