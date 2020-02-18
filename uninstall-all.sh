#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

release="${1:-prometheus-operator}"

clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"

for cluster in ${clusters}; do
    kubectl config use-context "${cluster}"
    printf "Unstalling %s from %s\n" "${release}" "${cluster}"
    helm uninstall "${release}"
done
