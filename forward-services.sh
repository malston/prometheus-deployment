#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

# Port forward services
kubectl --namespace "${namespace}" port-forward svc/grafana 3000:80 &
kubectl --namespace "${namespace}" port-forward svc/alertmanager-operated 9093 &
kubectl --namespace "${namespace}" port-forward svc/prometheus-oper-prometheus 9090 &
