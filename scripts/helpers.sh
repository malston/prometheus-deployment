#!/usr/bin/env bash

function credhub_login() {
	local credhub_server="${1}"
	local credhub_client="${2}"
	local credhub_secret="${3}"
	local credhub_ca_cert="${4}"

	echo "Logging in to credhub (${credhub_server})..."
	credhub login \
		--server="${credhub_server}" \
		--client-name="${credhub_client}" \
		--client-secret="${credhub_secret}" \
		--ca-cert="${credhub_ca_cert}"
}

function create-etcd-client-secret() {
	deployment=${1:?"bosh deployment name for service instance of the cluster"}

	credhub_login "${CREDHUB_SERVER}" "${CREDHUB_CLIENT}" "${CREDHUB_SECRET}" "${CREDHUB_CA_CERT}"

	credhub get -n "/p-bosh/${deployment}/tls-etcdctl-2018-2" -k ca > etcd-client-ca.crt
	credhub get -n "/p-bosh/${deployment}/tls-etcdctl-2018-2" -k certificate > etcd-client.crt
	credhub get -n "/p-bosh/${deployment}/tls-etcdctl-2018-2" -k private_key > etcd-client.key

	# Create secrets for etcd client cert
	kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found
	kubectl create secret -n "${namespace}" generic etcd-client \
		--from-file=etcd-client-ca.crt \
		--from-file=etcd-client.crt \
		--from-file=etcd-client.key
}

function create_federated_targets() {
	local cluster_name="${1}"
	local domain="${2}"
	local targets=()
	local clusters
	clusters=$(pks clusters --json | jq 'sort_by(.name)')

	for row in $(echo "${clusters}" | jq -r '.[] | @base64'); do
		_jq() {
		echo "${row}" | base64 --decode | jq -r "${1}"
		}
		targets=( "${targets[@]}" "prometheus.$(_jq '.name').${domain}" )
	done

	local current_target=("prometheus.$(echo "${cluster_name}").${domain}")
	for target in "${current_target[@]}"; do
		for i in "${!targets[@]}"; do
		if [[ "${targets[i]}" = "${target}" ]]; then
			unset "targets[i]"
		fi
		done
	done
	fed_targets="$(echo ${targets[*]})"
	fed_targets="${fed_targets// /, }"
	echo "[${fed_targets}]"
}

function interpolate() {
    foundation="${1:?"Foundation name required"}"
    cluster="${2:?"Cluster name required"}"
    deployment="service-instance_$(pks show-cluster "${cluster}" --json | jq -r .uuid)"

    export VARS_service_instance_id="${deployment}"
    export VARS_cluster_name="${cluster}"

    foundation_domain=$(om interpolate -s \
        --config "environments/${foundation}/config/config.yml" \
        --vars-file "environments/${foundation}/vars/vars.yml" \
        --vars-env VARS \
        --path "/clusters/cluster_name=${cluster}/foundation_domain")

    master_ips=$(bosh -d "${deployment}" vms --column=Instance --column=IPs | grep master | awk '{print $2}' | sort)
    master_node_ips="$(echo ${master_ips[*]})"
    export VARS_endpoints="[${master_node_ips// /, }]"
    VARS_federated_targets=$(create_federated_targets "${cluster}" "${foundation_domain}")
    export VARS_federated_targets

	set -x

    # Replace config variables in config.yaml
    om interpolate \
        --config "environments/${foundation}/config/config.yml" \
        --vars-file "environments/${foundation}/vars/vars.yml" \
        --vars-env VARS \
        --path /clusters/cluster_name="${cluster}" \
        > /tmp/vars.yml

    # Replace config variables in overrides.yaml
    om interpolate \
        --config "values/overrides.yaml" \
        --vars-file /tmp/vars.yml \
        > /tmp/overrides.yaml

    # Replace config variables in alertmanager.yaml
    om interpolate \
        --config "values/alertmanager.yaml" \
        --vars-file /tmp/vars.yml \
        >> /tmp/overrides.yaml

    is_master=$(om interpolate -s \
        --config "environments/${foundation}/config/config.yml" \
        --vars-file "environments/${foundation}/vars/vars.yml" \
        --vars-env VARS \
        --path "/clusters/cluster_name=${cluster}/is_master")

    if [[ $is_master == true ]]; then
      # Replace config variables in master prometheus/grafana.yaml (contains /federate targets)
      om interpolate --config "values/prometheus-federation.yaml" --vars-file /tmp/vars.yml >> /tmp/overrides.yaml
      om interpolate --config "values/grafana-federation.yaml" --vars-file /tmp/vars.yml >> /tmp/overrides.yaml
    else
      # Replace config variables in federated prometheus/grafana.yaml
      om interpolate --config "values/prometheus.yaml" --vars-file /tmp/vars.yml >> /tmp/overrides.yaml
      om interpolate --config "values/grafana.yaml" --vars-file /tmp/vars.yml >> /tmp/overrides.yaml
    fi

    cat /tmp/overrides.yaml
}

function create_secrets() {
	foundation="${1:?"Foundation name required to create secrets"}"
	cluster="${2:?"Cluster name required to create secrets"}"
	namespace="${3:?"Namespace required to create secrets"}"

	deployment="service-instance_$(pks show-cluster "${cluster}" --json | jq -r .uuid)"

	create-etcd-client-secret "${deployment}"

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
		# shellcheck disable=SC1091
		source "./create-bosh-exporter-secrets.sh" "${cluster}"
	fi

	pks_monitor_enabled="$(om interpolate -s --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS --path "/clusters/cluster_name=${cluster}/pks_monitor_enabled")"
	if [[ $pks_monitor_enabled == true ]]; then
		# shellcheck disable=SC1091
		source "./create-pks-monitor-uaa-client.sh" "${cluster}"
	fi
}

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

	interpolate "${foundation}" "${cluster}"

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