#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

kubectl get pods -n monitoring -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' \
    | sort | uniq
