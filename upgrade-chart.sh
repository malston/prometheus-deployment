#!/usr/bin/env bash

version="${1:?"Version is required"}"

helm repo update

helm fetch \
  --repo https://kubernetes-charts.storage.googleapis.com \
  --untar \
  --untardir ./charts \
  --version "${version}" \
    prometheus-operator

# Update the requirements.lock
cd ./charts/prometheus-operator || exit
helm dep update
