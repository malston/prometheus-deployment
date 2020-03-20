#!/bin/bash -e

if [ -z "${FOUNDATION}" ]; then
  echo "Enter an environment name (e.g. haas-420): "
  read -r FOUNDATION
fi

export CONCOURSE_URL="https://concourse.${FOUNDATION}.pez.pivotal.io"

printf "\n\n Concourse admin password: %s\n\n" "${CONCOURSE_PASSWORD}"


fly -t concourse login -c "${CONCOURSE_URL}" -u admin -k
