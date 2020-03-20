#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

helm template prometheus-operator ./charts/prometheus-operator --include-crds 2>/dev/null \
  | grep "image: " | awk '{print $2}' | uniq | sed 's/\"//g' > /tmp/images.txt
helm template prometheus-operator ./charts/prometheus-operator --include-crds 2>/dev/null \
  | grep config-reloader | grep :v | awk '{split($0,a,"="); print a[2]}' | sed 's/\"//g' >> /tmp/images.txt

cat /tmp/images.txt | sort
