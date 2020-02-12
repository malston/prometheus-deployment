#!/bin/bash -e

CREDS=$(om -t "$OM_TARGET" --skip-ssl-validation curl --silent \
     -p /api/v0/deployed/director/credentials/bosh_commandline_credentials | \
  jq -r .credential | sed 's/bosh //g')

# this will set BOSH_CLIENT, BOSH_ENVIRONMENT, BOSH_CLIENT_SECRET, and BOSH_CA_CERT
# however, BOSH_CA_CERT will be a path that is only valid on the OM VM
array=($CREDS)
for VAR in ${array[@]}; do
  export $VAR
done

OM_KEY=${1:-~/.ssh/om_rsa_key}
export BOSH_ALL_PROXY="ssh+socks5://ubuntu@$OM_TARGET:22?private-key=$OM_KEY"

export BOSH_CA_CERT="$(om -t $OM_TARGET --skip-ssl-validation certificate-authorities -f json | \
    jq -r '.[] | select(.active==true) | .cert_pem')"

export CREDHUB_CLIENT=$BOSH_CLIENT
export CREDHUB_SECRET=$BOSH_CLIENT_SECRET
export CREDHUB_CA_CERT=$BOSH_CA_CERT
export CREDHUB_SERVER="https://$BOSH_ENVIRONMENT:8844"
export CREDHUB_PROXY=$BOSH_ALL_PROXY
