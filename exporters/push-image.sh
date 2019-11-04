#!/bin/bash

set -eo pipefail

set -x

docker_image="${1:?"Docker image is required"}"
docker_image_tag="${2:?"Docker image tag is required"}"
project="${3:?"Harbor project name is required"}"

if [[ -z "${HARBOR_ADMIN_PASSWORD}" ]]; then
  echo "Enter the password for the harbor administrator account: "
  read -rs HARBOR_ADMIN_PASSWORD
fi

if [[ -z "${HARBOR_URL}" ]]; then
  echo "Enter the dns hostname for harbor: (e.g. harbor.example.com)"
  read -r HARBOR_URL
fi

# docker pull "${docker_image}"
docker login "https://${HARBOR_URL}" --username admin --password "${HARBOR_ADMIN_PASSWORD}"
docker tag "${docker_image}:${docker_image_tag}" "${HARBOR_URL}/${project}/${docker_image}:${docker_image_tag}"
docker push "${HARBOR_URL}/${project}/${docker_image}:${docker_image_tag}"
