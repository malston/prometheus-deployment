#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__PWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

target="${CONCOURSE_TARGET:-concourse}"

fly -t "${target}" set-pipeline \
    -p "prometheus-operator" \
    -c "${__PWD}/pipeline.yml" \
    -l "${__PWD}/pipeline-params.yml" \
    -l "${__PWD}/creds.yml"