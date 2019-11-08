#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl delete secret -n "${namespace}" etcd-client

kubectl delete --recursive --filename ./manifests/prometheus-operator

kubectl delete --recursive --filename ./templates
