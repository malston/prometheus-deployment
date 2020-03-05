#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

docker_image_name="malston/bats-promtool"
docker_image_tag="1.1.0"
prometheus_version="2.16.0"

docker build --build-arg prometheus_version="${prometheus_version}" -f ./docker-files/Dockerfile.bats-promtool -t "${docker_image_name}:${docker_image_tag}" .

docker login
docker tag "${docker_image_name}:${docker_image_tag}" "${docker_image_name}:${docker_image_tag}"
docker push "${docker_image_name}:${docker_image_tag}"
# docker login "https://${HARBOR_HOSTNAME}" --username admin --password "${HARBOR_ADMIN_PASSWORD}"
# docker tag "${docker_image_name}:${docker_image_tag}" "${HARBOR_HOSTNAME}/library/${docker_image_name}:${docker_image_tag}"
# docker push "${HARBOR_HOSTNAME}/library/${docker_image_name}:${docker_image_tag}"