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

read -rp "Add federation scrape job? [y/n]" federation

if [[ ! $(kubectl get namespace "${namespace}") ]]; then
  kubectl create namespace "${namespace}"
fi

kubectl config set-context --current --namespace="${namespace}"

if [[ -z "${deployment}" ]]; then
  deployment="service-instance_$(pks show-cluster "$(kubectl config current-context)" --json | jq -r .uuid)"
fi

./get-certs.sh "${deployment}"

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

# Create storage class
kubectl delete storageclass thin-disk --ignore-not-found
kubectl create -f storage/storage-class.yaml

if [[ -z "${FOUNDATION}" ]]; then
  echo "Enter foundation name (e.g. haas-000): "
  read -r FOUNDATION
fi

./interpolate.sh "${FOUNDATION}" "${federation}"

pks_monitor_enabled=false
if [[ $federation =~ ^[Yy]$ ]]; then
  pks_monitor_enabled=true
fi

# Copy dashboards to grafana chart location
cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

# Install prometheus-operator
helm upgrade -i --version "${version}" "${release}" \
    --namespace "${namespace}" \
    --values /tmp/overrides.yaml \
    --set bosh-exporter.boshExporter.enabled=true \
    --set pks-monitor.pksMonitor.enabled=${pks_monitor_enabled} \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set kubeTargetVersionOverride="$(kubectl version --short | grep -i server | awk '{print $3}' |  cut -c2-1000)" \
    ./charts/prometheus-operator

# Remove copied dashboards
rm charts/prometheus-operator/charts/grafana/dashboards/*.json