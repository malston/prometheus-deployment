#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

deployment=${1:?"bosh deployment name for service instance of the cluster"}

bosh -d "${deployment}" scp "master/0:/var/vcap/jobs/kube-apiserver/config/etc* /var/vcap/jobs/kube-apiserver/config/kubernetes* /var/vcap/jobs/kube-controller-manager/config/ca.pem /var/vcap/jobs/kube-controller-manager/config/kube-controller-manager-cert.pem /var/vcap/jobs/kube-controller-manager/config/kube-controller-manager-private-key.pem" .

mv etcd-{ca,client-ca}.crt
mv {ca,kube-controller-manager-ca}.pem

