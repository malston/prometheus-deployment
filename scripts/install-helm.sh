#!/bin/bash

set -eou pipefail

function install_helm_cli {
  version="${HELM_CLI_VERSION:-v2.14.1}"
  os="${OS:-darwin}"
  arch="${ARCH:-amd64}"
  file="helm.tar.gz"
  trap "{ rm -f "$file" ; exit 255; }" EXIT
  wget -O $file https://storage.googleapis.com/kubernetes-helm/helm-${version}-${os}-${arch}.tar.gz
  tar -zxvf $file --strip=1 -C /tmp
  chmod +x /tmp/helm
  chmod +x /tmp/tiller
  sudo mv /tmp/helm /usr/local/bin/helm
  sudo mv /tmp/tiller /usr/local/bin/tiller
  rm $file
  type helm
  type tiller
}

install_helm_cli