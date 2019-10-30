#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl config set-context --current --namespace="${namespace}"

kubectl create secret -n "${namespace}" generic bosh-ca \
    --from-file=bosh-ca.crt

kubectl create -f exporters/bosh-exporter.yaml

kubectl exec -it $(kubectl get pod -l app=bosh-exporter -o jsonpath='{.items[0].metadata.name}') -c bosh-exporter -- wget bosh-exporter:9190/metrics -O metrics.txt
