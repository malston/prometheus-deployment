#!/bin/bash

set -eo pipefail

set -x

docker_image_name="${1:-"boshprometheus/bosh-exporter"}"
docker_image_tag="${2:-"latest"}"
project="${3:-"prometheus"}"
docker_release_tag="${4:-"3.3.0"}"

if [[ -z "${HARBOR_ADMIN_PASSWORD}" ]]; then
  echo "Enter the password for the harbor administrator account: "
  read -rs HARBOR_ADMIN_PASSWORD
fi

if [[ -z "${HARBOR_URL}" ]]; then
  echo "Enter the dns hostname for harbor: (e.g. harbor.example.com)"
  read -r HARBOR_URL
fi

docker pull "${docker_image_name}:${docker_image_tag}"
docker login "https://${HARBOR_URL}" --username admin --password "${HARBOR_ADMIN_PASSWORD}"
docker tag "${docker_image_name}:${docker_image_tag}" "${HARBOR_URL}/${project}/${docker_image_name}:${docker_release_tag}"
docker push "${HARBOR_URL}/${project}/${docker_image_name}:${docker_release_tag}"
