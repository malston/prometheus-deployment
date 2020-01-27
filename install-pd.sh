#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

namespace="${1:-monitoring}"

function usage() {
  echo "Usage:"
  echo "$0 <namespace>"
  echo ""
  echo "namespace:  namespace to deploy the prometheus operator (default: monitoring)"
  exit 1
}

if [ "${1}" == "-h" ] || [ "${1}" == "help" ] || [ "${1}" == "--help" ]; then
    usage
fi

export FOUNDATION="haas-440"
DOMAIN="${FOUNDATION}.pez.pivotal.io"
export CLUSTER_NAME
CLUSTER_NAME="$(kubectl config current-context)"

CLUSTER_NUM="$(echo "${CLUSTER_NAME}" | cut -c8-9)"

# Install prometheus-deployment with bosh-exporter and ingress
helm upgrade -i prometheus-deployment ./charts/prometheus-deployment \
  --namespace="${namespace}" \
  --set grafana.host="grafana-${CLUSTER_NUM}.${DOMAIN}" \
  --set prometheus.host="prometheus-${CLUSTER_NUM}.${DOMAIN}" \
  --set alertmanager.host="alertmanager-${CLUSTER_NUM}.${DOMAIN}"
