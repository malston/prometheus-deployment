#!/usr/bin/env bash

function main() {
  local release="${1}"
  local namespace="${2}"

  clusters="$(pks clusters --json | jq -r 'sort_by(.name) | .[] | select(.last_action_state=="succeeded") | .name')"

  for cluster in ${clusters}; do
      pks get-credentials "${cluster}"

      kubectl config use-context "${cluster}"
      kubectl config set-context --current --namespace="${namespace}"

      printf "Uninstalling %s from %s\n" "${release}" "${cluster}"
      helm uninstall "${release}"
      printf "\nFinished uninstalling %s from %s\n" "${release}" "${cluster}"
      printf "============================================================\n"
  done
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

release="${1:-$RELEASE}"
namespace="${2:-$NAMESPACE}"

if [[ -z "${release}" ]]; then
    echo "Release is required"
    exit 1
fi

if [[ -z "${namespace}" ]]; then
  echo "Namespace name is required"
  exit 1
fi

mkdir -p ~/.pks
cp pks-config/creds.yml ~/.pks/creds.yml

mkdir -p ~/.kube
cp kube-config/config ~/.kube/config

cd repo

main "${release}" "${namespace}"
