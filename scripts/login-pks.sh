#!/bin/bash -e

if [ -z "${PKS_DOMAIN_NAME}" ]; then
  echo "Enter domain: (e.g., pez.pivotal.io)"
  read -r PKS_DOMAIN_NAME
fi

if [ -z "${PKS_SUBDOMAIN_NAME}" ]; then
  echo "Enter subdomain: (e.g., haas-420)"
  read -r PKS_SUBDOMAIN_NAME
fi

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "${__DIR}/target-bosh.sh" ]] &&  \
  source "${__DIR}/target-bosh.sh" ||  \
  echo "target-bosh.sh not found"

ADMIN_PASSWORD=$(om -k credentials \
    -p pivotal-container-service \
    -c '.properties.uaa_admin_password' \
    -f secret)

printf "\n\nAdmin password: %s\n\n" "${ADMIN_PASSWORD}"

pks login -a \
    "https://api.pks.${PKS_SUBDOMAIN_NAME}.${PKS_DOMAIN_NAME}" \
    --skip-ssl-validation \
    -u admin \
    -p "${ADMIN_PASSWORD}"
