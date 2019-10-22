#!/usr/bin/env bash

namespace="${1:?"First argument must be a namespace"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl apply -f helm/prometheus-operator/crds/

# Install operator
helm template helm/prometheus-operator \
    --namespace "${namespace}" \
    --set prometheusOperator.createCustomResource=false \
    | kubectl apply -f -

# Port forward services
# kubectl --namespace "${namespace}" port-forward svc/prometheus-grafana 3000:80
# kubectl --namespace "${namespace}" port-forward svc/alertmanager-operated 9093
# kubectl --namespace "${namespace}" port-forward svc/prometheus-prometheus-oper-prometheus 9090
