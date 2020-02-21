#!/usr/bin/env bash

release="${1:-prometheus-operator}"

helm uninstall "${release}"
kubectl delete pvc prometheus-prometheus-operator-prometheus-db-prometheus-prometheus-operator-prometheus-0
