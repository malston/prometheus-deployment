#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

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

# Copy dashboards to grafana chart location
cp dashboards/*.json charts/prometheus-operator/charts/grafana/dashboards/

# Install operator
helm template \
    --name monitoring \
    --namespace "${namespace}" \
    --values ./values/offline-overrides.yaml \
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
