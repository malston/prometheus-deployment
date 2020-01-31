#!/usr/bin/env bash

function download_pks_ca_cert() {
    local namespace="${1}"
    local om_target="${2}"
    local om_username="${3}"
    local om_password="${4}"

    om -t "${om_target}" -u "${om_username}" -p "${om_password}" --skip-ssl-validation credentials \
      -p pivotal-container-service \
      --credential-reference .pivotal-container-service.pks_tls \
      --credential-field cert_pem > ./pks-ca.crt

    kubectl delete secret -n "${namespace}" "pks-api-cert" --ignore-not-found
    kubectl create secret -n "${namespace}" generic "pks-api-cert" \
      --from-file=cert.pem=./pks-ca.crt
}

function create_uaa_client() {
    local namespace="${1}"
    local om_target="${2}"
    local om_username="${3}"
    local om_password="${4}"
    local pks_api_hostname="${5}"
    local pks_api_monitor_secret="${6}"
    local admin_client_secret
    admin_client_secret="$(om -t "${om_target}" -u "${om_username}" -p "${om_password}" credentials --product-name pivotal-container-service --credential-reference .properties.pks_uaa_management_admin_client --credential-field secret)"
    
    uaac target https://${pks_api_hostname}:8443 --ca-cert ./pks-ca.crt
    uaac token client get admin -s "${admin_client_secret}"

    uaac client add pks-api-monitor \
      --access_token_validity=600 \
      --secret="${pks_api_monitor_secret}" \
      --authorized_grant_types=client_credentials  \
      --authorities="pks.clusters.manage"
    
    kubectl delete secret -n "${namespace}" "pks-api-monitor" --ignore-not-found
    kubectl create secret -n "${namespace}" generic "pks-api-monitor" \
    --from-literal=pks-api="https://${pks_api_hostname}" \
    --from-literal=uaa-client-id="pks-api-monitor" \
    --from-literal=uaa-client-secret="${pks_api_monitor_secret}"
}

if [ ! $# -eq 4 ]; then
    echo "must supply the following args <namespace> <om_target> <om_username> <om_password>"
    exit 1
fi

if [[ -z "${PKS_API_MONITOR_SECRET}" ]]; then
  echo "Enter a secret for the pks-monitor uaa client: "
  read -rs PKS_API_MONITOR_SECRET
fi

if [ -z "${PKS_DOMAIN_NAME}" ]; then
  echo "Enter domain: (e.g., pez.pivotal.io)"
  read -r PKS_DOMAIN_NAME
fi

if [ -z "${PKS_SUBDOMAIN_NAME}" ]; then
  echo "Enter subdomain: (e.g., haas-440)"
  read -r PKS_SUBDOMAIN_NAME
fi

namespace="${1}"
om_target="${2}"
om_username="${3}"
om_password="${4}"
pks_api_hostname="api.pks.${PKS_SUBDOMAIN_NAME}.${PKS_DOMAIN_NAME}"

kubectl config set-context --current --namespace="${namespace}"

download_pks_ca_cert "${namespace}" "${om_target}" "${om_username}" "${om_password}"
create_uaa_client "${namespace}" "${om_target}" "${om_username}" "${om_password}" "${pks_api_hostname}" "${PKS_API_MONITOR_SECRET}"
