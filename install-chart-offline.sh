#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl create -f charts/prometheus-operator/crds/

rm -rf manifests/
mkdir -p manifests/

# Install operator
helm template \
    --name prometheus \
    --namespace "${namespace}" \
    --values ./values/prometheus-operator.yaml \
    --values ./values/offline-overrides.yaml \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set prometheusOperator.tlsProxy.enabled=false \
    --set prometheusOperator.admissionWebhooks.patch.enabled=false \
    --set grafana.enabled=true \
    --set grafana.initChownData.enabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set grafana.defaultDashboardsEnabled=true \
    --set grafana.sidecar.dashboards.enabled=true \
    --set grafana.sidecar.datasources.enabled=true \
    --set kubeTargetVersionOverride="1.14.5" \
    --output-dir ./manifests \
    ./charts/prometheus-operator

kubectl apply --recursive --filename ./manifests/prometheus-operator

# kubectl expose deployment "$(kubectl get deployments -o jsonpath="{.items[0].metadata.name}")" \
#     --name=prometheus-grafana-lb \
#     --port=80 \
#     --target-port=3000 \
#     --type=LoadBalancer \
#     --namespace="${namespace}"

# Port forward services
# kubectl --namespace "${namespace}" port-forward svc/prometheus-grafana 3000:80
# kubectl --namespace "${namespace}" port-forward svc/alertmanager-operated 9093
# kubectl --namespace "${namespace}" port-forward svc/prometheus-prometheus-oper-prometheus 9090
