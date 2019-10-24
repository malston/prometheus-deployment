#!/usr/bin/env bash

helm fetch \
  --repo https://kubernetes-charts.storage.googleapis.com \
  --untar \
  --untardir ./charts \
  --version 6.21.0 \
    prometheus-operator
