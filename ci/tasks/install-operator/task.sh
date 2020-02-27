#!/usr/bin/env bash
function install() {
  local foundation="${1}"
  local namespace="${2}"
  local release="${3}"
  local version="${4}"
  local cluster="${5}"

  pks get-credentials "${cluster}"

  printf "Installing version %s of %s into %s\n" "${version}" "${release}" "${cluster}"
  install_cluster "${cluster}" "${foundation}" "${namespace}" "${release}" "${version}"

  printf "\nFinished installing version %s of %s into %s\n" "${version}" "${release}" "${cluster}"
  printf "============================================================\n"
}

function main() {
  local foundation="${1}"
  local namespace="${2}"
  local release="${3}"
  local version="${4}"
  local cluster="${5}"

  if [[ -n "${cluster}" ]]; then
    install "${foundation}" "${namespace}" "${release}" "${version}" "${cluster}"
    return $?
  fi

  clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"
  for cluster in ${clusters}; do
    install "${foundation}" "${namespace}" "${release}" "${version}"
  done
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
source "${__DIR}/../../../scripts/target-bosh.sh" "/root/.ssh/id_rsa"

# shellcheck disable=SC1090
source "${__DIR}/../../../scripts/helpers.sh"

foundation="${1:-$FOUNDATION}"
namespace="${2:-$NAMESPACE}"
release="${3:-$RELEASE}"
version="${4:-$VERSION}"
cluster="${5:-$CLUSTER_NAME}"

if [[ -z "${version}" ]]; then
  version="$(cat version/version)"
  if [[ -z "${version}" ]]; then
    echo "Version is required"
    exit 1
  fi
fi

if [[ -z "${foundation}" ]]; then
  echo "Foundation name is required"
  exit 1
fi

if [[ -z "${namespace}" ]]; then
  echo "Namespace name is required"
  exit 1
fi

if [[ -z "${release}" ]]; then
  echo "Release is required"
  exit 1
fi

mkdir -p ~/.pks
cp pks-config/creds.yml ~/.pks/creds.yml

mkdir -p ~/.kube
cp kube-config/config ~/.kube/config

cd repo

main "${foundation}" "${namespace}" "${release}" "${version}" "${cluster}"
