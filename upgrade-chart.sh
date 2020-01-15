#!/usr/bin/env bash

version="${1:?"Version is required"}"

helm fetch \
  --repo https://kubernetes-charts.storage.googleapis.com \
  --untar \
  --untardir ./charts \
  --version "${version}" \
    prometheus-operator
