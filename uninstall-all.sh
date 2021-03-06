#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

release="${1:-prometheus-operator}"

clusters="$(pks clusters --json | jq -r 'sort_by(.name) | .[] | select(.last_action_state=="succeeded") | .name')"

for cluster in ${clusters}; do
    kubectl config use-context "${cluster}"
    printf "Uninstalling %s from %s\n" "${release}" "${cluster}"
    helm uninstall "${release}"  > /dev/null 2>&1 || continue
    kubectl delete configmap bosh-target-groups
    kubectl delete pvc prometheus-prometheus-operator-prometheus-db-prometheus-prometheus-operator-prometheus-0
done
