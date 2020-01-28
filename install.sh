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

./get-certs.sh "${deployment}"

if [[ ! $(kubectl get namespace "${namespace}") ]]; then
  kubectl create namespace "${namespace}"
fi

kubectl config set-context --current --namespace="${namespace}"

# Create storage class
kubectl delete storageclass thin-disk --ignore-not-found
kubectl create -f storage/storage-class.yaml

# Create secrets for etcd client cert
kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found
kubectl create secret -n "${namespace}" generic etcd-client \
    --from-file=etcd-client-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key

kubectl delete configmap -n "${namespace}" bosh-target-groups --ignore-not-found
kubectl create configmap -n "${namespace}" bosh-target-groups --from-literal=bosh_target_groups\.json={}

if [[ -z "${GMAIL_ACCOUNT}" ]]; then
  echo "Email account: "
  read -r GMAIL_ACCOUNT
fi

if [[ -z "${GMAIL_AUTH_TOKEN}" ]]; then
  echo "Email password or auth token: "
  read -rs GMAIL_AUTH_TOKEN
fi

kubectl delete secret -n "${namespace}" "smtp-creds" --ignore-not-found
kubectl create secret -n "${namespace}" generic "smtp-creds" \
    --from-literal=user="${GMAIL_ACCOUNT}" \
    --from-literal=password="${GMAIL_AUTH_TOKEN}"

# Copy dashboards to grafana chart location
cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

export FOUNDATION="haas-440"
DOMAIN="${FOUNDATION}.pez.pivotal.io"
export SERVICE_INSTANCE_ID="${deployment}"
export CLUSTER_NAME
CLUSTER_NAME="$(kubectl config current-context)"
export ENDPOINTS
ips=$(bosh -d "${SERVICE_INSTANCE_ID}" vms --column=Instance --column=IPs | grep master | awk '{print $2}' | sort)
ENDPOINTS="$(echo ${ips[*]})"
ENDPOINTS="[${ENDPOINTS// /, }]"

CLUSTER_NUM="$(echo "${CLUSTER_NAME}" | cut -c8-9)"
export PROMETHEUS_URL="https://prometheus-${CLUSTER_NUM}.${DOMAIN}"
export ALERTMANAGER_URL="https://alertmanager-${CLUSTER_NUM}.${DOMAIN}"

envsubst < ./values/overrides.yaml > /tmp/overrides.yaml
envsubst < ./values/with-additional-scrape-configs.yaml > /tmp/with-additional-scrape-configs.yaml
envsubst < ./values/with-federation.yaml > /tmp/with-federation.yaml

scrape_config="--values /tmp/with-additional-scrape-configs.yaml"
if [[ $federation =~ ^[Yy]$ ]]; then
  scrape_config="--values /tmp/with-federation.yaml"
fi

# Install prometheus-operator
helm upgrade -i --version "${version}" "${release}" \
    --namespace "${namespace}" \
    --values /tmp/overrides.yaml \
    ${scrape_config} \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set kubeTargetVersionOverride="$(kubectl version --short | grep -i server | awk '{print $3}' |  cut -c2-1000)" \
    --set grafana.host="grafana-${CLUSTER_NUM}.${DOMAIN}" \
    --set prometheus.host="prometheus-${CLUSTER_NUM}.${DOMAIN}" \
    --set alertmanager.host="alertmanager-${CLUSTER_NUM}.${DOMAIN}" \
    ./charts/prometheus-operator

# Remove copied dashboards
rm charts/prometheus-operator/charts/grafana/dashboards/*.json
