#!/bin/bash

set -eou pipefail

function install_helm_cli {
  version="${HELM_CLI_VERSION:-v3.0.0-beta.5}"
  os="${OS:-darwin}"
  arch="${ARCH:-amd64}"
  file="helm.tar.gz"
  trap "{ rm -f "$file" ; exit 255; }" EXIT
  wget -O $file https://get.helm.sh/helm-${version}-${os}-${arch}.tar.gz
  tar -zxvf $file --strip=1 -C /tmp
  chmod +x /tmp/helm
  sudo mv /tmp/helm /usr/local/bin/helm3
  rm $file
  type helm3
}

install_helm_cli