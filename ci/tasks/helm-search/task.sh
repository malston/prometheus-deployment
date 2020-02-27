#!/usr/bin/env bash

function main() {
	local release="${1}"
	printf "Checking for newest version of chart\n"

	REPO_RELEASE="stable/${release}"
	
	helm search repo "${release}" -o json \
		| jq -r  --arg repo_release "$REPO_RELEASE" '.[] | select(.name==$repo_release) | .version' \
		> version/version
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

release="${1:-$RELEASE}"
chart_repo="${2:-$CHART_REPO}"

helm repo add stable "${chart_repo}"

if [[ -z "${release}" ]]; then
  echo "Release is required"
  exit 1
fi

main "${release}"
