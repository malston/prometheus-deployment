#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

deployment="${1}" #: bosh deployment name for service instance of the cluster
namespace="${2}"
federation="${3}"

function usage() {
  echo "Usage:"
  echo "$0 <deployment> <namespace> <federation>"
  echo ""
  echo "deployment: bosh deployment name for service instance of the cluster (default: derived from current-context)"
  echo "namespace: namespace to deploy the prometheus operator (default: monitoring)"
  echo "federation: if set then adds the federation scrape job (default: '')"
  exit 1
}

if [ "${1}" == "-h" ]; then
    usage
fi

if [ "$#" -gt 1 ] && [ "$#" -lt 3 ]; then
    usage
fi

if [[ -z "${deployment}" ]]; then
  cluster_name="$(kubectl config current-context)"
  service_guid=$(pks show-cluster "${cluster_name}" --json | jq -r .uuid)
  deployment="service-instance_${service_guid}"
fi

if [[ -z "${namespace}" ]]; then
  namespace="monitoring"
fi

if [[ -z "${federation}" ]]; then
  echo "Add federation scrape job? [Y/N]"
  read -r federation
fi

./get-etcd-certs.sh "${deployment}"

if [[ ! $(kubectl get namespace "${namespace}") ]]; then
  kubectl create namespace "${namespace}"
fi

kubectl config set-context --current --namespace="${namespace}"

rm -rf manifests/
mkdir -p manifests/

# Create CRDs
kubectl apply -f crds/

# Create secrets for etcd client cert
kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found
kubectl create secret -n "${namespace}" generic etcd-client \
    --from-file=etcd-client-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key

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

# Create configMaps for file service discovery
kubectl delete configmap -n "${namespace}" bosh-target-groups --ignore-not-found
kubectl create configmap -n "${namespace}" bosh-target-groups \
    --from-file=bosh_target_groups.json

# Copy dashboards to grafana chart location
cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

export SERVICE_INSTANCE_ID="${deployment}"
export CLUSTER_NAME="${cluster_name}"

envsubst < ./values/offline-overrides.yaml > /tmp/offline-overrides.yaml
envsubst < ./values/with-additional-scrape-configs.yaml > /tmp/with-additional-scrape-configs.yaml

if [[ "${federation}" = "Y" ]]; then
  with_federation="--values ./values/with-federation.yaml"
fi

# Install operator
helm template \
    --name monitoring \
    --namespace "${namespace}" \
    --values /tmp/offline-overrides.yaml \
    --values ./values/with-external-etcd.yaml \
    --values /tmp/with-additional-scrape-configs.yaml \
    ${with_federation} \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set kubeTargetVersionOverride="1.14.5" \
    --output-dir ./manifests \
    ./charts/prometheus-operator

# Apply all objects under manifests directory
kubectl apply --recursive --filename ./manifests

# Create services
kubectl apply -f services/

# Remove copied dashboards
rm charts/prometheus-operator/charts/grafana/dashboards/*.json
