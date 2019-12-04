#!/usr/bin/env bash

namespace="${1:-"monitoring"}"

kubectl delete secret -n "${namespace}" etcd-client --ignore-not-found

kubectl delete --recursive --filename ./manifests/prometheus-operator --ignore-not-found

kubectl delete --recursive --filename ./templates --ignore-not-found
