#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl create -f charts/prometheus-operator/crds/

# Create secrets for etcd client cert
kubectl create secret -n "${namespace}" generic etcd-client \
    --from-file=etcd-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key

rm -rf manifests/
mkdir -p manifests/

# Install operator
helm template \
    --name prometheus \
    --namespace "${namespace}" \
    --values ./values/prometheus-operator.yaml \
    --values ./values/offline-overrides.yaml \
    --values ./values/with-external-etcd.yaml \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set prometheusOperator.tlsProxy.enabled=true \
    --set prometheusOperator.admissionWebhooks.patch.enabled=true \
    --set grafana.enabled=true \
    --set grafana.initChownData.enabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set grafana.defaultDashboardsEnabled=true \
    --set grafana.sidecar.dashboards.enabled=true \
    --set grafana.sidecar.datasources.enabled=true \
    --set grafana.sidecar.datasources.defaultDatasourceEnabled=true \
    --set kubeTargetVersionOverride="1.14.5" \
    --output-dir ./manifests \
    ./charts/prometheus-operator

kubectl apply --recursive --filename ./manifests/prometheus-operator
