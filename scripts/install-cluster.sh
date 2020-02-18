#!/usr/bin/env bash

function install_cluster() {
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

	create_secrets "${foundation}" "${cluster}" "${namespace}"

	# shellcheck disable=SC1090
	source "${__DIR}/interpolate.sh" "${foundation}" "${cluster}"

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
}

function create_secrets() {
	foundation="${1:?"Foundation name required to create secrets"}"
	cluster="${2:?"Cluster name required to create secrets"}"
	namespace="${3:?"Namespace required to create secrets"}"

	deployment="service-instance_$(pks show-cluster "${cluster}" --json | jq -r .uuid)"

	# shellcheck disable=SC1090
	source "${__DIR}/get-etcd-certs.sh" "${deployment}"

	# Create secrets for etcd client cert
	kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found
	kubectl create secret -n "${namespace}" generic etcd-client \
		--from-file=etcd-client-ca.crt \
		--from-file=etcd-client.crt \
		--from-file=etcd-client.key

	kubectl delete configmap -n "${namespace}" bosh-target-groups --ignore-not-found
	kubectl create configmap -n "${namespace}" bosh-target-groups --from-literal=bosh_target_groups\.json={}

	# if [[ -z "${GMAIL_ACCOUNT}" ]]; then
	#   echo "Email account: "
	#   read -r GMAIL_ACCOUNT
	# fi

	# if [[ -z "${GMAIL_AUTH_TOKEN}" ]]; then
	#   echo "Email password or auth token: "
	#   read -rs GMAIL_AUTH_TOKEN
	# fi

	# kubectl delete secret -n "${namespace}" "smtp-creds" --ignore-not-found
	# kubectl create secret -n "${namespace}" generic "smtp-creds" \
	#     --from-literal=user="${GMAIL_ACCOUNT}" \
	#     --from-literal=password="${GMAIL_AUTH_TOKEN}"

	bosh_exporter_enabled="$(om interpolate -s --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS --path "/clusters/cluster_name=${cluster}/bosh_exporter_enabled")"
	if [[ $bosh_exporter_enabled == true ]]; then
		# shellcheck disable=SC1090
		source "${__DIR}/create-bosh-exporter-secrets.sh" "${cluster}"
	fi

	pks_monitor_enabled="$(om interpolate -s --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS --path "/clusters/cluster_name=${cluster}/pks_monitor_enabled")"
	if [[ $pks_monitor_enabled == true ]]; then
		# shellcheck disable=SC1090
		source "${__DIR}/create-pks-monitor-uaa-client.sh" "${cluster}"
	fi
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
