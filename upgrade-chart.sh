#!/usr/bin/env bash

version="${version:-8.3.3}"

helm fetch \
  --repo https://kubernetes-charts.storage.googleapis.com \
  --untar \
  --untardir ./charts \
  --version "${version}" \
    prometheus-operator
