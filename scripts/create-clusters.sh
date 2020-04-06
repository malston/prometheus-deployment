#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

external_hostname="${1:-${EXTERNAL_HOSTNAME}}"

if [ -z "${external_hostname}" ]; then
  echo "Enter cluster domain: (e.g., haas-000.pez.pivotal.io)"
  read -r external_hostname
fi

for i in $(seq 3); do
    pks create-cluster "cluster0$i" --num-nodes 1 \
        --external-hostname "cluster0$i.$external_hostname" \
        --plan small --non-interactive
done
