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
    targets=( "${targets[@]}" "prometheus-$(_jq '.name' | cut -c8-9).${DOMAIN}" )
  done

  local current_target=("prometheus-$(echo "${cluster_name}" | cut -c8-9).${domain}")
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

foundation=${1:?"Foundation name required"}
federation=${2:?"Federation required [Y/N]"}

deployment="service-instance_$(pks show-cluster "$(kubectl config current-context)" --json | jq -r .uuid)"

export VARS_service_instance_id="${deployment}"

master_ips=$(bosh -d "${deployment}" vms --column=Instance --column=IPs | grep master | awk '{print $2}' | sort)
master_node_ips="$(echo ${master_ips[*]})"
export VARS_endpoints="[${master_node_ips// /, }]"
VARS_cluster_name="$(kubectl config current-context)"
export VARS_cluster_name
VARS_federation_targets=$(create_federation_targets "${VARS_cluster_name}" "${foundation}.pez.pivotal.io")
export VARS_federation_targets

om interpolate --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS > /tmp/vars.yml
om interpolate --config "values/overrides.yaml" --vars-file /tmp/vars.yml > /tmp/overrides.yaml

if [[ $federation =~ ^[Yy]$ ]]; then
  om interpolate --config "values/with-federation.yaml" --vars-file /tmp/vars.yml >> /tmp/overrides.yaml
else
  om interpolate --config "values/with-additional-scrape-configs.yaml" --vars-file /tmp/vars.yml >> /tmp/overrides.yaml
fi
