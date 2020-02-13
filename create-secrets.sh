#!/usr/bin/env bash

foundation="${1:?"Foundation name required to create secrets"}"
cluster="${2:?"Cluster name required to create secrets"}"
namespace="${3:?"Namespace required to create secrets"}"

deployment="service-instance_$(pks show-cluster "${cluster}" --json | jq -r .uuid)"

# shellcheck disable=SC1091
source ./get-etcd-certs.sh "${deployment}"

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
  ./create-bosh-exporter-secrets.sh "${cluster}"
fi

pks_monitor_enabled="$(om interpolate -s --config "environments/${foundation}/config/config.yml" --vars-file "environments/${foundation}/vars/vars.yml" --vars-env VARS --path "/clusters/cluster_name=${cluster}/pks_monitor_enabled")"
if [[ $pks_monitor_enabled == true ]]; then
  ./create-pks-monitor-uaa-client.sh "${cluster}"
fi
