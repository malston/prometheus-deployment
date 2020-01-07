#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

deployment="${1}" #: bosh deployment name for service instance of the cluster
namespace="${2:-monitoring}"
release="${3:-prometheus-operator}"
version="${4:-8.5.4}"

function usage() {
  echo "Usage:"
  echo "$0 <deployment> <namespace>"
  echo ""
  echo "deployment: bosh deployment name for service instance of the cluster (default: derived from current-context)"
  echo "namespace:  namespace to deploy the prometheus operator (default: monitoring)"
  exit 1
}

if [ "${1}" == "-h" ] || [ "${1}" == "help" ] || [ "${1}" == "--help" ]; then
    usage
fi

if [[ -z "${deployment}" ]]; then
  deployment="service-instance_$(pks show-cluster "$(kubectl config current-context)" --json | jq -r .uuid)"
fi

read -rp "Add federation scrape job? [y/n]" federation

# ./get-certs.sh "${deployment}"

if [[ ! $(kubectl get namespace "${namespace}") ]]; then
  kubectl create namespace "${namespace}"
fi

kubectl config set-context --current --namespace="${namespace}"

export FOUNDATION="haas-440"
export SERVICE_INSTANCE_ID="${deployment}"
export CLUSTER_NAME
CLUSTER_NAME="$(kubectl config current-context)"
export ENDPOINTS
ips=$(bosh -d "${SERVICE_INSTANCE_ID}" vms --column=Instance --column=IPs | grep master | awk '{print $2}' | sort)
ENDPOINTS="$(echo ${ips[*]})"
ENDPOINTS="[${ENDPOINTS// /, }]"

export PROMETHEUS_URL="http://prometheus-01.haas-440.pez.pivotal.io"
export ALERTMANAGER_URL="http://alertmanager-01.haas-440.pez.pivotal.io"

envsubst < ./values/overrides.yaml > /tmp/overrides.yaml
envsubst < ./values/with-additional-scrape-configs.yaml > /tmp/with-additional-scrape-configs.yaml
envsubst < ./values/with-federation.yaml > /tmp/with-federation.yaml

scrape_config="--values /tmp/with-additional-scrape-configs.yaml"
if [[ $federation =~ ^[Yy]$ ]]; then
  scrape_config="--values /tmp/with-federation.yaml"
fi

# Install operator
helm upgrade --version "${version}" "${release}" \
    --namespace "${namespace}" \
    --values /tmp/overrides.yaml \
    ${scrape_config} \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set kubeTargetVersionOverride="1.14.5" \
    ./charts/prometheus-operator
