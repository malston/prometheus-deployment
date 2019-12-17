#!/usr/bin/env bash

helm fetch \
  --repo https://kubernetes-charts.storage.googleapis.com \
  --untar \
  --untardir ./charts \
  --version 8.3.3 \
    prometheus-operator
