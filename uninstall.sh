#!/usr/bin/env bash

release="${1:-prometheus-operator}"

helm uninstall "${release}"
