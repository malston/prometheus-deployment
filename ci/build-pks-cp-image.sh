#!/usr/bin/env bash

# ./build-image.sh $PIVNET_TOKEN /Users/malston/.ssh/haas-440.pub

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

pivnet_token="${1:?"Must supply pivnet token"}"
opsman_ssh_key="${2:?"Must supply path to opsman private ssh key"}"

docker_image_name="malston/pks-control-plane"
docker_image_tag="0.0.1"

docker build --build-arg pivnet_token="${pivnet_token}" --build-arg opsman_ssh_key="$(cat "${opsman_ssh_key}")" -f ./docker-files/Dockerfile.pks-control-plane -t "${docker_image_name}:${docker_image_tag}" .

docker login
docker tag "${docker_image_name}:${docker_image_tag}" "${docker_image_name}:${docker_image_tag}"
docker push "${docker_image_name}:${docker_image_tag}"
# docker login "https://${HARBOR_HOSTNAME}" --username admin --password "${HARBOR_ADMIN_PASSWORD}"
# docker tag "${docker_image_name}:${docker_image_tag}" "${HARBOR_HOSTNAME}/library/${docker_image_name}:${docker_image_tag}"
# docker push "${HARBOR_HOSTNAME}/library/${docker_image_name}:${docker_image_tag}"