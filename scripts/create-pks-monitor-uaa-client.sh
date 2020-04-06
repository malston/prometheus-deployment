#!/usr/bin/env bash

function download_pks_ca_cert() {
    local namespace="${1}"
    local om_target="${2}"
    local om_username="${3}"
    local om_password="${4}"

    om -t "${om_target}" -k -u "${om_username}" -p "${om_password}" --skip-ssl-validation credentials \
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
    admin_client_secret="$(om -t "${om_target}" -k -u "${om_username}" -p "${om_password}" credentials --product-name pivotal-container-service --credential-reference .properties.pks_uaa_management_admin_client --credential-field secret)"
    
    uaac target https://${pks_api_hostname}:8443 --ca-cert ./pks-ca.crt --skip-ssl-validation
    uaac token client get admin -s "${admin_client_secret}"

    ok="$(uaac client get pks-api-monitor || echo "NotFound")"
    if [[ "${ok}" != *NotFound* ]]; then
      echo "Deleting pks-api-monitor uaa client"
      uaac client delete pks-api-monitor
    fi

    echo "Adding pks-api-monitor uaa client"
    uaac client add pks-api-monitor \
      --access_token_validity=600 \
      --secret="${pks_api_monitor_secret}" \
      --authorized_grant_types=client_credentials  \
      --authorities="pks.clusters.admin.read"
    
    kubectl delete secret -n "${namespace}" "pks-api-monitor" --ignore-not-found
    kubectl create secret -n "${namespace}" generic "pks-api-monitor" \
    --from-literal=pks-api="https://${pks_api_hostname}" \
    --from-literal=uaa-client-id="pks-api-monitor" \
    --from-literal=uaa-client-secret="${pks_api_monitor_secret}"
}

cluster="${1:-${CLUSTER}}"
namespace="${2:-${NAMESPACE}}"
om_target="${3:-${OM_TARGET}}"
om_username="${4:-${OM_USERNAME}}"
om_password="${5:-${OM_PASSWORD}}"
pks_api_hostname="${6:-${PKS_API_HOSTNAME}}"
pks_api_monitor_secret="${7:-${PKS_API_MONITOR_SECRET}}"

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

if [ -z "${pks_api_hostname}" ]; then
  echo "Enter subdomain: (e.g., api.pks.haas-000.pez.pivotal.io)"
  read -r pks_api_hostname
fi

if [[ -z "${pks_api_monitor_secret}" ]]; then
  echo "Enter a secret for the pks-monitor uaa client: "
  read -rs pks_api_monitor_secret
fi

kubectl config set-context --current --namespace="${namespace}"

download_pks_ca_cert "${namespace}" "${om_target}" "${om_username}" "${om_password}"
create_uaa_client "${namespace}" "${om_target}" "${om_username}" "${om_password}" "${pks_api_hostname}" "${pks_api_monitor_secret}"
