#!/usr/bin/env bash

function download_bosh_ca_cert() {
    om_target="${1}"
    om_username="${2}"
    om_password="${3}"

    om -t "${om_target}" -u "${om_username}" -p "${om_password}" --skip-ssl-validation certificate-authorities -f json | \
        jq -r '.[] | select(.active==true) | .cert_pem' > ./bosh-ca.crt
}

if [ ! $# -eq 4 ]
  then
    echo "must supply the following args <namespace> <om_target> <om_username> <om_password>"
    exit 1
fi

namespace="${1}"
om_target="${2}"
om_username="${3}"
om_password="${4}"

kubectl config set-context --current --namespace="${namespace}"

download_bosh_ca_cert "${om_target}" "${om_username}" "${om_password}"

kubectl delete secret -n "${namespace}" bosh-ca --ignore-not-found

kubectl create secret -n "${namespace}" generic bosh-ca \
    --from-file=./bosh-ca.crt

kubectl apply --recursive --filename ./templates/exporters

sleep 5

kubectl logs "$(kubectl get pod -l app=bosh-exporter -o jsonpath='{.items[0].metadata.name}')"
