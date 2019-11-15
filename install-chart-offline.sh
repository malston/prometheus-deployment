#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

if [[ ! $(kubectl get namespace "${namespace}") ]]; then
  kubectl create namespace "${namespace}"
fi

kubectl config set-context --current --namespace="${namespace}"

rm -rf manifests/
mkdir -p manifests/

# Create CRDs
kubectl apply -f crds/

# Create secrets for etcd client cert
kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found
kubectl create secret -n "${namespace}" generic etcd-client \
    --from-file=etcd-client-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key

if [[ -z "${GMAIL_ACCOUNT}" ]]; then
  echo "Email account: "
  read -r GMAIL_ACCOUNT
fi

if [[ -z "${GMAIL_AUTH_TOKEN}" ]]; then
  echo "Email password or auth token: "
  read -rs GMAIL_AUTH_TOKEN
fi

kubectl create secret -n "${namespace}" generic "smtp-creds" \
    --from-literal=user="${GMAIL_ACCOUNT}" \
    --from-literal=password="${GMAIL_AUTH_TOKEN}"

# Create configMaps for file service discovery
kubectl delete configmap -n "${namespace}" bosh-target-groups --ignore-not-found
kubectl create configmap -n "${namespace}" bosh-target-groups \
    --from-file=bosh_target_groups.json

# Copy dashboards to grafana chart location
cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

# # Create SC/PVC for bosh_target_groups file
# cat <<EOF | kubectl apply -f -
# apiVersion: storage.k8s.io/v1
# kind: StorageClass
# metadata:
#   name: thin-disk
# provisioner: kubernetes.io/vsphere-volume
# parameters:
#     diskformat: thin
# EOF

# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   name: bosh-target-groups
# spec:
#   storageClassName: thin-disk
#   capacity:
#     storage: 1Gi
#   accessModes:
#     - ReadWriteOnly
# EOF

# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: PersistentVolumeClaim
# metadata:
#   name: bosh-target-groups-claim
#   namespace: ${namespace}
#   annotations:
#     volume.beta.kubernetes.io/storage-class: thin-disk
# spec:
#   accessModes:
#     - ReadWriteOnce
#   resources:
#     requests:
#       storage: 1Mi
# EOF

envsubst < ./values/offline-overrides.yaml > /tmp/offline-overrides.yaml

# Install operator
helm template \
    --name monitoring \
    --namespace "${namespace}" \
    --values /tmp/offline-overrides.yaml \
    --values ./values/with-external-etcd.yaml \
    --values ./values/with-additional-scrape-configs.yaml \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set kubeTargetVersionOverride="1.14.5" \
    --output-dir ./manifests \
    ./charts/prometheus-operator

# Apply all objects under manifests directory
kubectl apply --recursive --filename ./manifests

# Create services
kubectl apply -f services/

# Remove copied dashboards
rm charts/prometheus-operator/charts/grafana/dashboards/*.json
