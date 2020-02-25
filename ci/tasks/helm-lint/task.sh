#!/usr/bin/env bash

function main() {
  local repo="${1}"
  local release_name="${2}"
  local namespace="${2}"

  cd "${repo}/charts/${release_name}" || exit

  clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"

  for cluster in ${clusters}; do
    pks get-credentials "${cluster}"

    switch_namespace "${cluster}" "${namespace}"

    printf "Linting %s on %s\n" "${release_name}" "${cluster}"
    helm lint

    printf "\nFinished linting %s on %s\n" "${release_name}" "${cluster}"
    printf "============================================================\n"
  done
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

if [[ -z "${namespace}" ]]; then
  echo "Namespace name is required"
  exit 1
fi

mkdir -p ~/.pks
cp pks-config/creds.yml ~/.pks/creds.yml

mkdir -p ~/.kube
cp kube-config/config ~/.kube/config

main "repo" "${release}" "${namespace}"
