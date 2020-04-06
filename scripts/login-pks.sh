#!/bin/bash -e

if [ -z "${PKS_API_HOSTNAME}" ]; then
  echo "Enter domain: (e.g., api.pks.pez.pivotal.io)"
  read -r PKS_API_HOSTNAME
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
    "https://${PKS_API_HOSTNAME}" \
    --skip-ssl-validation \
    -u admin \
    -p "${ADMIN_PASSWORD}"
