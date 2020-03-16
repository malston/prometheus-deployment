#!/bin/bash -e

if [ -z "${ENVIRONMENT_NAME}" ]; then
  echo "Enter an environment name (e.g. haas-420): "
  read -r ENVIRONMENT_NAME
fi

export CONCOURSE_URL="https://plane.${ENVIRONMENT_NAME}.pez.pivotal.io"

printf "\n\n Concourse admin password: %s\n\n" "${CONCOURSE_PASSWORD}"


fly -t concourse login -c "${CONCOURSE_URL}" -u admin -k
