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

function create_etcd_client_secret() {
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

function get_excluded_targets() {
	local foundation="${1}"
	local cluster="${2}"
	local release="${3}"
	local excluded_targets=()

	# for each cluster in pks clusters
	# login to cluster
	# check that the operator is NOT installed (helm list)
	# if operator is NOT installed then it is added to the list of excluded target
	# return list of excluded targets

	clusters="$(pks clusters --json | jq -r 'sort_by(.name) | .[] | select(.last_action_state=="succeeded") | .name')"
	for cluster in ${clusters}; do
		pks get-credentials "${cluster}"
		kubectl config use-context "${cluster}"
		kubectl config set-context --current --namespace="${namespace}"

		release_name="$(helm list -q -f "${release}")"
		if [[ -z "${release_name}" ]]; then
			prometheus_hostname=$(om interpolate -s \
				--config "environments/${foundation}/config/config.yml" \
				--vars-file "environments/${foundation}/vars/vars.yml" \
				--vars-env VARS \
				--path "/clusters/cluster_name=${cluster}/prometheus_hostname")
			excluded_targets=( "${excluded_targets[@]}" "${prometheus_hostname}" )
		fi
	done
	echo "${excluded_targets[*]}"
}

function create_federated_targets() {
	local foundation="${1}"
	fed_targets=$(get_federated_targets "${foundation}")
	fed_targets="${fed_targets// /, }"
	echo "[${fed_targets}]"
}

function get_federated_targets() {
	local foundation="${1}"
	local targets=()
	local clusters
	clusters=$(pks clusters --json | jq 'sort_by(.name)')

	for row in $(echo "${clusters}" | jq -r '.[] | @base64'); do
		_jq() {
			echo "${row}" | base64 --decode | jq -r "${1}"
		}
		cluster=$(_jq '.name')
		prometheus_hostname=$(om interpolate -s \
			--config "environments/${foundation}/config/config.yml" \
			--vars-file "environments/${foundation}/vars/vars.yml" \
			--vars-env VARS \
			--path "/clusters/cluster_name=${cluster}/prometheus_hostname")
		if [[ ${prometheus_hostname} ]]; then
			targets=( "${targets[@]}" "${prometheus_hostname}" )
		fi
	done

	echo "${targets[*]}"
}

function interpolate() {
    foundation="${1:?"Foundation name required"}"
    cluster="${2:?"Cluster name required"}"
    namespace="${3:?"Namespace required"}"
    deployment="service-instance_$(pks show-cluster "${cluster}" --json | jq -r .uuid)"

    export VARS_service_instance_id="${deployment}"
    export VARS_cluster_name="${cluster}"
    export VARS_namespace="${namespace}"

    master_ips=$(bosh -d "${deployment}" vms --column=Instance --column=IPs | grep master | awk '{print $2}' | sort)
    master_node_ips="$(echo ${master_ips[*]})"
    export VARS_endpoints="[${master_node_ips// /, }]"
    VARS_federated_targets=$(create_federated_targets "${foundation}")
    export VARS_federated_targets

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
        --vars-env VARS \
        > /tmp/overrides.yaml

    # Replace config variables in alertmanager.yaml
    om interpolate \
        --config "values/alertmanager.yaml" \
        --vars-file /tmp/vars.yml \
        --vars-env VARS \
        >> /tmp/overrides.yaml

    is_master=$(om interpolate -s \
        --config "environments/${foundation}/config/config.yml" \
        --vars-file "environments/${foundation}/vars/vars.yml" \
        --vars-env VARS \
        --path "/clusters/cluster_name=${cluster}/is_master")

    if [[ $is_master == true ]]; then
      # Replace config variables in master prometheus/grafana.yaml (contains /federate targets)
      om interpolate \
          --config "values/prometheus-federation.yaml" \
		  --vars-file /tmp/vars.yml \
          --vars-env VARS \
		  >> /tmp/overrides.yaml
      om interpolate \
          --config "values/grafana-federation.yaml" \
		  --vars-file /tmp/vars.yml \
          --vars-env VARS \
		  >> /tmp/overrides.yaml
    else
      # Replace config variables in federated prometheus/grafana.yaml
      om interpolate \
    	  --config "values/prometheus.yaml" \
		  --vars-file /tmp/vars.yml \
          --vars-env VARS \
		  >> /tmp/overrides.yaml
      om interpolate \
	      --config "values/grafana.yaml" \
		  --vars-file /tmp/vars.yml \
          --vars-env VARS \
		  >> /tmp/overrides.yaml
    fi

    cat /tmp/overrides.yaml
}

function create_secrets() {
	foundation="${1:?"Foundation name required to create secrets"}"
	cluster="${2:?"Cluster name required to create secrets"}"
	namespace="${3:?"Namespace required to create secrets"}"

	deployment="service-instance_$(pks show-cluster "${cluster}" --json | jq -r .uuid)"

	create_etcd_client_secret "${deployment}"

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

	# Create the initial bosh-target-groups configmap
	# Prometheus will not start if this does not exist; the bosh-exporter will
	# recreate it when it is scraped
	kubectl delete configmap -n "${namespace}" bosh-target-groups --ignore-not-found
	kubectl create configmap -n "${namespace}" bosh-target-groups \
	    --from-literal=bosh-target-groups="{}"

	bosh_exporter_enabled=$(get_config_value "${foundation}" "/clusters/cluster_name=${cluster}/bosh_exporter_enabled")
	if [[ $bosh_exporter_enabled == true ]]; then
		# shellcheck disable=SC1090
		source "${__PWD}/create-bosh-exporter-secrets.sh" "${cluster}"
	fi

	pks_monitor_enabled=$(get_config_value "${foundation}" "/clusters/cluster_name=${cluster}/pks_monitor_enabled")
	if [[ $pks_monitor_enabled == true ]]; then
		# shellcheck disable=SC1090
		source "${__PWD}/create-pks-monitor-uaa-client.sh" "${cluster}"
	fi
}

function helm_install() {
	cluster="${1:?"Cluster name is required"}"
	namespace="${2:?"Namespace is required"}"
	release="${3:?"Release is required"}"
	bosh_exporter_enabled="${4:-"false"}"
	pks_monitor_enabled="${5:-"false"}"

	excluded_targets=()
	is_cluster_canary=$(om interpolate -s \
		--config "environments/${foundation}/config/config.yml" \
		--vars-file "environments/${foundation}/vars/vars.yml" \
		--vars-env VARS \
		--path "/clusters/cluster_name=${cluster}/is_canary")
	
	if [[ "${is_cluster_canary}" ]]; then
		excluded_targets=("$(get_excluded_targets "${foundation}" "${cluster}" "${release}" 2>/dev/null)")
	fi

	echo "excluded_targets: '${excluded_targets[*]}'"
	foundation_domain=$(om interpolate -s \
		--config "environments/${foundation}/config/config.yml" \
		--vars-file "environments/${foundation}/vars/vars.yml" \
		--vars-env VARS \
		--path "/clusters/cluster_name=${cluster}/foundation_domain")
	echo "clusterDomain: '${cluster}.${foundation_domain}'"

	helm upgrade -i "${release}" \
		--namespace "${namespace}" \
		--values /tmp/overrides.yaml \
		--set bosh-exporter.boshExporter.enabled="${bosh_exporter_enabled}" \
		--set pks-monitor.pksMonitor.enabled="${pks_monitor_enabled}" \
		--set global.rbac.pspEnabled=false \
		--set grafana.adminPassword=admin \
		--set grafana.testFramework.enabled=true \
		--set ingress-gateway.istio.enabled=true \
		--set ingress-gateway.ingress.enabled=false \
		--set ingress-gateway.clusterDomain="${cluster}.${foundation_domain}" \
		--set smoke-tests.excludedTargets="${excluded_targets[*]}" \
		--set kubeTargetVersionOverride="$(kubectl version --short | grep -i server | awk '{print $3}' |  cut -c2-1000)" \
		"${__BASEDIR}/charts/prometheus-operator"
}

function create_namespace() {
	cluster="${1:?"Cluster name is required"}"
	namespace="${2:?"Namespace is required"}"

	if ! kubectl get namespace "${namespace}" > /dev/null 2>&1; then
		kubectl create namespace "${namespace}"
	fi
}

function switch_namespace() {
	cluster="${1:?"Cluster name is required"}"
	namespace="${2:?"Namespace is required"}"

	kubectl config use-context "${cluster}"

	kubectl config set-context "${cluster}" --namespace="${namespace}"
}

function create_storage_class() {
	kubectl delete storageclass thin-disk --ignore-not-found
	kubectl create -f storage/storage-class.yaml
}

function copy_dashboards() {
    foundation="${1:?"Foundation name required"}"
    cluster="${2:?"Cluster name required"}"

	is_master=$(om interpolate -s \
		--config "environments/${foundation}/config/config.yml" \
		--vars-file "environments/${foundation}/vars/vars.yml" \
		--vars-env VARS \
		--path "/clusters/cluster_name=${cluster}/is_master")

	cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/
	if [[ $is_master == true ]]; then
		rm charts/prometheus-operator/charts/grafana/dashboards/kubeapi-slo.json
	else
		rm charts/prometheus-operator/charts/grafana/dashboards/kubeapi-slo-federation.json
	fi
}

function remove_dashboards() {
	rm charts/prometheus-operator/charts/grafana/dashboards/*.json
	git checkout charts/prometheus-operator/charts/grafana/dashboards/custom-dashboard.json
}

function get_config_value() {
	foundation="${1}"
	path="${2}"

	output="$(om interpolate -s \
		--config "environments/${foundation}/config/config.yml" \
		--vars-file "environments/${foundation}/vars/vars.yml" \
		--vars-env VARS \
		--path "${path}")"

	echo "$output"
}

function install_cluster() {
	foundation="${1:?"Foundation name is required"}"
	cluster="${2:?"Cluster name is required"}"
	namespace="${3:?"Namespace is required"}"
	release="${4:?"Release is required"}"

	create_namespace "${cluster}" "${namespace}"

	switch_namespace "${cluster}" "${namespace}"

	create_storage_class

	create_secrets "${foundation}" "${cluster}" "${namespace}"

	interpolate "${foundation}" "${cluster}" "${namespace}"

	copy_dashboards "${foundation}" "${cluster}"

	bosh_exporter_enabled=$(get_config_value "${foundation}" "/clusters/cluster_name=${cluster}/bosh_exporter_enabled")
	pks_monitor_enabled=$(get_config_value "${foundation}" "/clusters/cluster_name=${cluster}/pks_monitor_enabled")

	helm_install "${cluster}" "${namespace}" "${release}" "${bosh_exporter_enabled}" "${pks_monitor_enabled}"

	remove_dashboards
}

__PWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__BASEDIR="${__PWD}/.."