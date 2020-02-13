#!/usr/bin/env bash

function usage() {
  echo "Usage:"
  echo "$0 <foundation> <namespace>"
  echo ""
  echo "foundation: ops manager foundation name"
  echo "namespace:  namespace to deploy the prometheus operator (default: monitoring)"
  exit 1
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

foundation="${1:-$FOUNDATION}"
namespace="${2:-monitoring}"
release="${3:-prometheus-operator}"
version="${4:-8.5.4}"

if [ "${1}" == "-h" ] || [ "${1}" == "help" ] || [ "${1}" == "--help" ]; then
  usage
fi

if [[ -z "${foundation}" ]]; then
  echo "Enter foundation name (e.g. haas-000): "
  read -r foundation
fi

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
source "${__DIR}/scripts/target-bosh.sh"

cluster=$(kubectl config current-context)

# shellcheck disable=SC1091
source ./install_cluster.sh "${cluster}" "${foundation}" "${namespace}" "${release}" "${version}"
