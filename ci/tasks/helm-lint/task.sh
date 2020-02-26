#!/usr/bin/env bash

function main() {
  local repo="${1}"
  local release_name="${2}"

  cd "${repo}/charts/${release_name}" || exit

  printf "Linting %s\n" "${release_name}"
  helm lint

  printf "\nFinished linting %s\n" "${release_name}"
  printf "============================================================\n"
  cd -
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
source "${__DIR}/../../../scripts/helpers.sh"

release="${1:-$RELEASE}"

if [[ -z "${release}" ]]; then
  echo "Release is required"
  exit 1
fi

main "repo" "${release}"
