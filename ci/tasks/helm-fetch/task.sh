#!/usr/bin/env bash

function main() {
  local repo="${1}"
  local release="${2}"
  local version="${3}"
  local chart_repo="${4}"
  
  printf "Fetch %s of %s chart from %s\n" "${version}" "${release}" "${chart_repo}"

  helm fetch \
    --repo "${chart_repo}" \
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
chart_repo="${3:-$CHART_REPO}"

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

if [[ -z "${chart_repo}" ]]; then
  echo "Chart repository is required"
  exit 1
fi

main "repo" "${release}" "${version}" "${chart_repo}"
