#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl delete --recursive --filename ./manifests/prometheus-operator
