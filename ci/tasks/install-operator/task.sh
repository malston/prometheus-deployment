#!/usr/bin/env bash
function install() {
  local foundation="${1}"
  local cluster="${2}"
  local namespace="${3}"
  local release="${4}"
  local version="${5}"

  printf "Logging into k8s cluster (%s)..." "${cluster}"
  pks get-credentials "${cluster}"

  printf "Installing %s into %s\n" "${release}" "${cluster}"

  install_cluster "${foundation}" "${cluster}" "${namespace}" "${release}"

  printf "\nFinished installing %s into %s\n" "${release}" "${cluster}"
  printf "============================================================\n"
}

function main() {
  local canary="${1}"
  local foundation="${2}"
  local cluster="${3}"
  local namespace="${4}"
  local release="${5}"
  local version="${6}"

  clusters_in_order_of_upgrade=$(om interpolate -s --config "environments/${foundation}/config/config.yml" \
      --vars-file "environments/${foundation}/vars/vars.yml" \
      --vars-env VARS \
      --path "/clusters" | \
      grep cluster_name | awk '{print $NF}')

  for cluster in ${clusters_in_order_of_upgrade}; do
    is_cluster_canary=$(om interpolate -s \
          --config "environments/${foundation}/config/config.yml" \
          --vars-file "environments/${foundation}/vars/vars.yml" \
          --vars-env VARS \
          --path "/clusters/cluster_name=${cluster}/is_canary")

    if [[ "${is_cluster_canary}" == "${canary}" ]]; then
      install "${foundation}" "${cluster}" "${namespace}" "${release}" "${version}"
    fi
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

canary="${1:-$CANARY}"
foundation="${2:-$FOUNDATION}"
cluster="${3:-$CLUSTER_NAME}"
namespace="${4:-$NAMESPACE}"
release="${5:-$RELEASE}"
version="${6:-$VERSION}"

if [[ -z "${canary}" ]]; then
  canary="false"
fi

if [[ -z "${foundation}" ]]; then
  echo "Foundation name is required"
  exit 1
fi

if [[ -z "${cluster}" ]]; then
  echo "Cluster name is required"
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
  version="$(cat version/version)"
fi

mkdir -p ~/.pks
cp pks-config/creds.yml ~/.pks/creds.yml

mkdir -p ~/.kube
cp kube-config/config ~/.kube/config

cd repo

main "${canary}" "${foundation}" "${cluster}" "${namespace}" "${release}" "${version}"
