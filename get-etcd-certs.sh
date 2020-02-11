#!/usr/bin/env bash

function credhub_login() {
	local credhub_server="${1}"
	local credhub_client="${2}"
	local credhub_secret="${3}"
	local credhub_ca_cert="${4}"

	credhub login \
		--server="${credhub_server}" \
		--client-name="${credhub_client}" \
		--client-secret="${credhub_secret}" \
		--ca-cert="${credhub_ca_cert}"
}

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

deployment=${1:?"bosh deployment name for service instance of the cluster"}

credhub_login "${CREDHUB_SERVER}" "${CREDHUB_CLIENT}" "${CREDHUB_SECRET}" "${CREDHUB_CA_CERT}"

credhub get -n "/p-bosh/${deployment}/tls-etcdctl-2018-2" -k ca > etcd-client-ca.crt
credhub get -n "/p-bosh/${deployment}/tls-etcdctl-2018-2" -k certificate > etcd-client.crt
credhub get -n "/p-bosh/${deployment}/tls-etcdctl-2018-2" -k private_key > etcd-client.key