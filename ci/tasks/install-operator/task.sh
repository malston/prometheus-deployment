#!/usr/bin/env bash

function main() {
  local foundation="${1}"
  local namespace="${2}"
  local release="${3}"
  local version="${4}"

  clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"
  for cluster in ${clusters}; do
    kubectl config set-context "${cluster}"
    
    if [[ ! $(kubectl get namespace "${namespace}") ]]; then
      kubectl create namespace "${namespace}"
    fi
    kubectl config set-context "${cluster}" --namespace="${namespace}"

    # Create storage class
    kubectl delete storageclass thin-disk --ignore-not-found
    kubectl create -f ./storage/storage-class.yaml

    ./create-secrets.sh "${foundation}" "${cluster}" "${namespace}"

    ./interpolate.sh "${foundation}" "${cluster}"

    # Copy dashboards to grafana chart location
    cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

    bosh_exporter_enabled="$(om interpolate -s --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS --path "/clusters/cluster_name=${cluster}/bosh_exporter_enabled")"
    pks_monitor_enabled="$(om interpolate -s --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS --path "/clusters/cluster_name=${cluster}/pks_monitor_enabled")"
    
    # Install prometheus-operator
    helm upgrade -i --version "${version}" "${release}" \
        --namespace "${namespace}" \
        --values /tmp/overrides.yaml \
        --set bosh-exporter.boshExporter.enabled="${bosh_exporter_enabled}" \
        --set pks-monitor.pksMonitor.enabled="${pks_monitor_enabled}" \
        --set global.rbac.pspEnabled=false \
        --set grafana.adminPassword=admin \
        --set grafana.testFramework.enabled=false \
        --set kubeTargetVersionOverride="$(kubectl version --short | grep -i server | awk '{print $3}' |  cut -c2-1000)" \
        ./charts/prometheus-operator

    # Remove copied dashboards
    rm charts/prometheus-operator/charts/grafana/dashboards/*.json
  done
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

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

cd prometheus-deployment

main "${foundation}" "${namespace}" "${release}" "${version}"
