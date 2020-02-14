#!/usr/bin/env bash

cluster="${1:?"Cluster name is required"}"
foundation="${2:?"Foundation name is required"}"
namespace="${3:?"Namespace is required"}"
release="${4:?"Release is required"}"
version="${5:?"Version is required"}"

kubectl config use-context "${cluster}"

if [[ ! $(kubectl get namespace "${namespace}") ]]; then
	kubectl create namespace "${namespace}"
fi
kubectl config set-context --current --namespace="${namespace}"

# Create storage class
kubectl delete storageclass thin-disk --ignore-not-found
kubectl create -f storage/storage-class.yaml

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
	--set ingress-gateway.ingress.enabled=false \
	--set kubeTargetVersionOverride="$(kubectl version --short | grep -i server | awk '{print $3}' |  cut -c2-1000)" \
	./charts/prometheus-operator

# Remove copied dashboards
rm charts/prometheus-operator/charts/grafana/dashboards/*.json
