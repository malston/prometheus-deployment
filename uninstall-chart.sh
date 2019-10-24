#!/usr/bin/env bash

namespace="${1:?"First argument must be a namespace"}"

kubectl create namespace "${namespace}"

kubectl delete --recursive --filename ./manifests/prometheus-operator