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

function create_secret() {
    local namespace="${1}"
    local secret_name="${2}"
    local uaa_client_id="${3}"
    local uaa_client_secret="${4}"

    kubectl delete secret -n "${namespace}" "${secret_name}" --ignore-not-found
    kubectl create secret -n "${namespace}" generic "${secret_name}" \
      --from-literal="uaa-client-id=${uaa_client_id}" \
      --from-literal="uaa-client-secret=${uaa_client_secret}"
}

cluster="${1:-${CLUSTER}}"
namespace="${2:-${NAMESPACE}}"
om_target="${3:-${OM_TARGET}}"
om_username="${4:-${OM_USERNAME}}"
om_password="${5:-${OM_PASSWORD}}"
bosh_uaa_client_id="${6:-${BOSH_UAA_CLIENT_ID}}"
bosh_uaa_client_secret="${7:-${BOSH_UAA_CLIENT_SECRET}}"

if [ -z "${cluster}" ]; then
  echo "Enter cluster name: "
  read -r cluster
fi

if [ -z "${namespace}" ]; then
  echo "Enter namespace: "
  read -r namespace
fi

if [ -z "${om_target}" ]; then
  echo "Enter ops manager hostname: (e.g., opsman.haas-000.pez.pivotal.io) "
  read -r om_target
fi

if [[ -z "${om_username}" ]]; then
  echo "Enter a username for the opsman administrator account: "
  read -r om_username
fi

if [[ -z "${om_password}" ]]; then
  echo "Enter a password for the opsman administrator account: "
  read -rs om_password
fi

if [ -z "${bosh_uaa_client_id}" ]; then
  echo "Enter BOSH UAA Client ID: "
  read -r bosh_uaa_client_id
fi

if [[ -z "${bosh_uaa_client_secret}" ]]; then
  echo "Enter BOSH UAA Client Secret: "
  read -rs bosh_uaa_client_secret
fi

kubectl config set-context "${cluster}" --namespace="${namespace}"

download_bosh_ca_cert "${om_target}" "${om_username}" "${om_password}"
create_secret_from_file "${namespace}" "bosh-ca" "./bosh-ca.crt"
create_secret "${namespace}" "bosh-exporter" "${bosh_uaa_client_id}" "${bosh_uaa_client_secret}"