#!/usr/bin/env bash

function helm_test() {
  local release_name="${1}"
  local namespace="${2}"
  local cluster="${3}"

  pks get-credentials "${cluster}"

  switch_namespace "${cluster}" "${namespace}"

  release="$(helm list -q -f "${release_name}")"
  if [[ -z "${release}" ]]; then
    printf "%s release not found" "${release_name}"
    exit 1
  fi

  printf "Testing %s on %s\n" "${release_name}" "${cluster}"
  helm test "${release_name}"

  printf "\nFinished testing %s on %s\n" "${release_name}" "${cluster}"
  printf "============================================================\n"
}

function main() {
  local release_name="${1}"
  local namespace="${2}"
  local cluster="${3}"

  if [[ -n "${cluster}" ]]; then
    helm_test "${release_name}" "${namespace}" "${cluster}"
    return $?
  fi

  clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"

  for cluster in ${clusters}; do
    helm_test "${release_name}" "${namespace}" "${cluster}"
  done
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
source "${__DIR}/../../../scripts/helpers.sh"

release="${1:-$RELEASE}"
namespace="${2:-$NAMESPACE}"
cluster="${3:-$CLUSTER_NAME}"

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

main "${release}" "${namespace}" "${cluster}"
