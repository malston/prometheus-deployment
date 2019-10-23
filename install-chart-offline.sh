#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl apply -f helm/prometheus-operator/crds/

# Create Dashboard ConfigMaps
kubectl apply -f helm/prometheus-operator/configmaps/

# Install operator
helm template helm/prometheus-operator \
    -f helm/prometheus-operator/offline-values.yaml \
    --name=prometheus \
    --namespace "${namespace}" \
    --set prometheusOperator.createCustomResource=false \
    --set global.rbac.pspEnabled=false \
    --set prometheusOperator.tlsProxy.enabled=false \
    --set prometheusOperator.admissionWebhooks.patch.enabled=false \
    --set grafana.initChownData.enabled=false \
    --set grafana.adminPassword=admin \
    --set grafana.testFramework.enabled=false \
    --set defaultDashboardsEnabled=false \
    --set sidecar.dashboards.enabled=true \
    | kubectl apply -f -

# kubectl expose deployment "$(kubectl get deployments -o jsonpath="{.items[0].metadata.name}")" --name=prometheus-grafana-lb --port=80 --target-port=3000 --type=LoadBalancer --namespace="${namespace}"

# Port forward services
# kubectl --namespace "${namespace}" port-forward svc/prometheus-grafana 3000:80
# kubectl --namespace "${namespace}" port-forward svc/alertmanager-operated 9093
# kubectl --namespace "${namespace}" port-forward svc/prometheus-prometheus-oper-prometheus 9090
