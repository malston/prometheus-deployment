#!/usr/bin/env bash

function create_federation_targets() {
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

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# ./interpolate.sh "${FOUNDATION}" "${cluster}"
foundation=${1:?"Foundation name required"}
cluster_name=${2:?"Cluster name required"}

deployment="service-instance_$(pks show-cluster "${cluster_name}" --json | jq -r .uuid)"

export VARS_service_instance_id="${deployment}"
export VARS_cluster_name="${cluster_name}"

master_ips=$(bosh -d "${deployment}" vms --column=Instance --column=IPs | grep master | awk '{print $2}' | sort)
master_node_ips="$(echo ${master_ips[*]})"
export VARS_endpoints="[${master_node_ips// /, }]"
VARS_federation_targets=$(create_federation_targets "${cluster_name}" "${foundation}.pez.pivotal.io")
export VARS_federation_targets

# Replace config variables in config.yaml
om interpolate \
    --config "environments/${foundation}/config/config.yml" \
    --vars-file "environments/${foundation}/vars/vars.yml" \
    --vars-env VARS \
    --path /clusters/cluster_name="${cluster_name}" \
    > /tmp/vars.yml

cat /tmp/vars.yml

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
    --path "/clusters/cluster_name=${cluster_name}/is_master")

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