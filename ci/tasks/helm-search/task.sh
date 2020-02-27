#!/usr/bin/env bash

function main() {
	printf "Checking for newest version of chart\n"
	
	helm search repo prometheus-operator -o json \
		| jq -r '.[] | select(.name=="stable/prometheus-operator") | .version' \
		> ../chart-version/version
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

main
