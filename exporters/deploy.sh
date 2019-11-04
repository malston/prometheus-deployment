#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl config set-context --current --namespace="${namespace}"

kubectl delete secret -n "${namespace}" bosh-ca --ignore-not-found

kubectl create secret -n "${namespace}" generic bosh-ca \
    --from-file=bosh-ca.crt

kubectl delete -f bosh-exporter.yaml --ignore-not-found

sleep 5

kubectl create -f bosh-exporter.yaml

sleep 5

# kubectl logs $(kubectl get pod -l app=bosh-exporter -o jsonpath='{.items[0].metadata.name}')

echo
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
echo
echo 'Must create a DNAT address to translate to one of the Node IPS above'
echo
# Must create a DNAT address to translate to one of the Node IPS above
curl -k -v http://10.197.74.201:30123/metrics

# kubectl exec -it $(kubectl get pod -l app=bosh-exporter -o jsonpath='{.items[0].metadata.name}') -c bosh-exporter -- wget bosh-exporter:9190/metrics
