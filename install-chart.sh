#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl apply -f charts/prometheus-operator/crds/

# Install operator
helm3 install monitoring stable/prometheus-operator \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set prometheusOperator.createCustomResource=false
