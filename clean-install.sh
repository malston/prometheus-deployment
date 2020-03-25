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

${__DIR}/uninstall.sh

kubectl get crds | grep coreos | awk '{print $1}' | while read i; do k delete crd $i; done
kubectl get clusterrolebindings | grep prometheus-operator | awk '{print $1}' | while read i; do echo kubectl delete $i; done
kubectl get clusterroles | grep prometheus-operator | awk '{print $1}' | while read i; do echo kubectl delete $i; done
kubectl get mutatingwebhookconfigurations | grep prometheus-operator | awk '{print $1}' | while read i; do echo kubectl delete $i; done
kubectl get validatingwebhookconfigurations | grep prometheus-operator | awk '{print $1}' | while read i; do echo kubectl delete $i; done
kubectl get podsecuritypolicies | grep prometheus-operator | awk '{print $1}' | while read i; do echo kubectl delete $i; done
