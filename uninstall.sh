#!/usr/bin/env bash

namespace="${1:-"monitoring"}"
release="${2:-prometheus-operator}"

helm uninstall "${release}"

kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found

kubectl delete pvc prometheus-prometheus-operator-prometheus-db-prometheus-prometheus-operator-prometheus-0
