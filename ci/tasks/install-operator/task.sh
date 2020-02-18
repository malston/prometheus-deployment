#!/usr/bin/env bash

function main() {
  local foundation="${1}"
  local namespace="${2}"
  local release="${3}"
  local version="${4}"

  clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"
  for cluster in ${clusters}; do
    printf "Installing %s into %s\n" "${release}" "${cluster}"
    pks get-credentials "${cluster}"

    # shellcheck disable=SC1090
    source "${__DIR}/../../install_cluster.sh"
    install_cluster "${cluster}" "${foundation}" "${namespace}" "${release}" "${version}"

    printf "\nFinished installing %s into %s\n" "${release}" "${cluster}"
    printf "============================================================\n\n"
  done
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
source "${__DIR}/../../../scripts/target-bosh.sh" "/root/.ssh/id_rsa"

foundation="${1:-$FOUNDATION}"
namespace="${2:-$NAMESPACE}"
release="${3:-$RELEASE}"
version="${4:-$VERSION}"

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

if [[ -z "${version}" ]]; then
  echo "Version is required"
  exit 1
fi

mkdir -p ~/.pks
cp pks-config/creds.yml ~/.pks/creds.yml

mkdir -p ~/.kube
cp kube-config/config ~/.kube/config

cd prometheus-deployment

main "${foundation}" "${namespace}" "${release}" "${version}"
