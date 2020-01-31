#!/usr/bin/env bash

function download_bosh_ca_cert() {
    local om_target="${1}"
    local om_username="${2}"
    local om_password="${3}"

    om -t "${om_target}" -u "${om_username}" -p "${om_password}" --skip-ssl-validation certificate-authorities -f json | \
        jq -r '.[] | select(.active==true) | .cert_pem' > ./bosh-ca.crt
}

function create_secret_from_file() {
    local namespace="${1}"
    local secret_name="${2}"
    local file="${3}"

    kubectl delete secret -n "${namespace}" "${secret_name}" --ignore-not-found
    kubectl create secret -n "${namespace}" generic "${secret_name}" \
      --from-file="${file}"
}

if [ ! $# -eq 4 ]; then
    echo "must supply the following args <namespace> <om_target> <om_username> <om_password>"
    exit 1
fi

namespace="${1}"
om_target="${2}"
om_username="${3}"
om_password="${4}"

kubectl config set-context --current --namespace="${namespace}"

download_bosh_ca_cert "${om_target}" "${om_username}" "${om_password}"
create_secret_from_file "${namespace}" "bosh-ca" "./bosh-ca.crt"
