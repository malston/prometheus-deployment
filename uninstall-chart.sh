#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl create namespace "${namespace}"

kubectl delete --recursive --filename ./manifests/prometheus-operator