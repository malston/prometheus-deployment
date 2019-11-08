#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl config set-context --current --namespace="${namespace}"

kubectl delete secret -n "${namespace}" bosh-ca --ignore-not-found

kubectl create secret -n "${namespace}" generic bosh-ca \
    --from-file=./bosh-ca.crt

kubectl delete -f bosh-exporter.yaml --ignore-not-found

kubectl create -f bosh-exporter.yaml

sleep 5

kubectl logs "$(kubectl get pod -l app=bosh-exporter -o jsonpath='{.items[0].metadata.name}')"
