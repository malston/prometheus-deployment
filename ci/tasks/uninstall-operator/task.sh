#!/usr/bin/env bash

function main() {
  local release="${1}"

  clusters="$(pks clusters --json | jq 'sort_by(.name)' | jq -r .[].name)"

  for cluster in ${clusters}; do
      printf "Uninstalling %s from %s\n" "${release}" "${cluster}"
      pks get-credentials "${cluster}"

      kubectl config use-context "${cluster}"
      helm uninstall "${release}"
      printf "\nFinished uninstalling %s from %s\n" "${release}" "${cluster}"
      printf "============================================================\n\n"
  done
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

release="${3:-$RELEASE}"

if [[ -z "${release}" ]]; then
    echo "Release is required"
    exit 1
fi

mkdir -p ~/.pks
cp pks-config/creds.yml ~/.pks/creds.yml

mkdir -p ~/.kube
cp kube-config/config ~/.kube/config

cd prometheus-deployment

main "${release}"
