#!/usr/bin/env bash

function main() {
	printf "Checking for newest version of chart\n"
	
	helm search repo prometheus-operator -o json \
		| jq -r '.[] | select(.name=="stable/prometheus-operator") | .version' \
		> version/version
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

helm repo add stable https://kubernetes-charts.storage.googleapis.com

main
