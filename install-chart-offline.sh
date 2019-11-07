#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl create -f crds/

# Create secrets for etcd client cert
kubectl create secret -n "${namespace}" generic etcd-client \
    --from-file=etcd-client-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key

# Copy custom dashboards
cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

rm -rf manifests/
mkdir -p manifests/

# Install operator
helm template \
    --name monitoring \
    --namespace "${namespace}" \
    --values ./values/offline-overrides.yaml \
    --values ./values/with-external-etcd.yaml \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set kubeTargetVersionOverride="1.14.5" \
    --output-dir ./manifests \
    ./charts/prometheus-operator

kubectl apply --recursive --filename ./manifests/prometheus-operator

rm charts/prometheus-operator/charts/grafana/dashboards/*.json
