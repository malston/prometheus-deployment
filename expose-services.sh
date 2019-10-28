#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl expose deployment "$(kubectl get deployments -n namespace="${namespace}" -o jsonpath="{.items[0].metadata.name}")" \
    --name=prometheus-grafana-lb \
    --port=80 \
    --target-port=3000 \
    --type=LoadBalancer \
    --namespace="${namespace}"

kubectl expose deployment "$(kubectl get deployments -n namespace="${namespace}" -o jsonpath="{.items[0].metadata.name}")" \
    --name=prometheus-alertmanager-lb \
    --port=80 \
    --target-port=9093 \
    --type=LoadBalancer \
    --namespace="${namespace}"

kubectl expose deployment "$(kubectl get deployments -n namespace="${namespace}" -o jsonpath="{.items[0].metadata.name}")" \
    --name=prometheus-prometheus-lb \
    --port=80 \
    --target-port=9090 \
    --type=LoadBalancer \
    --namespace="${namespace}"
