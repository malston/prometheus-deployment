#!/usr/bin/env bash

namespace="${1:?"First argument must be a namespace"}"

kubectl create namespace "${namespace}"

kubectl config set-context --current --namespace="${namespace}"

# Create CRDs
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml

# Install operator
helm3 install prometheus stable/prometheus-operator \
    --set global.rbac.pspEnabled=false \
    --set grafana.adminPassword=admin \
    --set prometheusOperator.createCustomResource=false

kubectl expose deployment "$(kubectl get deployments -o jsonpath="{.items[0].metadata.name}")" \
    --name=prometheus-grafana-lb \
    --port=80 \
    --target-port=3000 \
    --type=LoadBalancer \
    --namespace="${namespace}"

# Port forward services
# kubectl --namespace "${namespace}" port-forward svc/prometheus-grafana 3000:80
# kubectl --namespace "${namespace}" port-forward svc/alertmanager-operated 9093
# kubectl --namespace "${namespace}" port-forward svc/prometheus-prometheus-oper-prometheus 9090
