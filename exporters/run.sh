#!/usr/bin/env bash

export BOSH_EXPORTER_WEB_LISTEN_ADDRESS="127.0.0.1:9190"
export BOSH_EXPORTER_BOSH_LOG_LEVEL="DEBUG"
export BOSH_EXPORTER_BOSH_URL="172.16.1.11"
export BOSH_EXPORTER_BOSH_UAA_CLIENT_ID="ops_manager"
export BOSH_EXPORTER_BOSH_UAA_CLIENT_SECRET="EdyCNlv4r3bArQY1__HgucBwQj6VGStq"
export BOSH_EXPORTER_BOSH_CA_CERT_FILE="./bosh-ca.crt"
export BOSH_EXPORTER_METRICS_ENVIRONMENT=pks
export BOSH_EXPORTER_METRICS_NAMESPACE=""
export BOSH_EXPORTER_FILTER_COLLECTORS="Deployments,Jobs,ServiceDiscovery"

LOG_DIR=./log
rm -rf ${LOG_DIR}
mkdir -p ${LOG_DIR}

killall bosh_exporter
rm bosh_exporter
make build

./bosh_exporter >> ${LOG_DIR}/bosh_exporter.stdout.log \
      2>> ${LOG_DIR}/bosh_exporter.stderr.log &

# curl -k -v http://127.0.0.1:9190/metrics
