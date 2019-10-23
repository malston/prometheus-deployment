#!/usr/bin/env bash

namespace="${1:?"First argument must be a namespace"}"

kubectl create namespace "${namespace}"

for i in $(kubectl get deploy | grep prometheus | awk '{print $1}'); do kubectl delete deploy "$i"; done
for i in $(kubectl get configmaps | grep prometheus | awk '{print $1}'); do kubectl delete configmaps "$i"; done
for i in $(kubectl get statefulset | grep prometheus | awk '{print $1}'); do kubectl delete statefulset "$i"; done
for i in $(kubectl get daemonset | grep prometheus | awk '{print $1}'); do kubectl delete daemonset "$i"; done
for i in $(kubectl get crd | grep coreos | awk '{print $1}'); do kubectl delete crd "$i"; done
for i in $(kubectl get psp | grep prometheus | awk '{print $1}'); do kubectl delete psp "$i"; done
for i in $(kubectl get secret | grep prometheus | awk '{print $1}'); do kubectl delete secret "$i"; done
for i in $(kubectl get serviceaccount | grep prometheus | awk '{print $1}'); do kubectl delete serviceaccount "$i"; done
for i in $(kubectl get clusterrole | grep prometheus | awk '{print $1}'); do kubectl delete clusterrole "$i"; done
for i in $(kubectl get clusterrolebinding | grep prometheus | awk '{print $1}'); do kubectl delete clusterrolebinding "$i"; done
for i in $(kubectl get role | grep prometheus | awk '{print $1}'); do kubectl delete role "$i"; done
for i in $(kubectl get rolebinding | grep prometheus | awk '{print $1}'); do kubectl delete rolebinding "$i"; done
for i in $(kubectl get svc -n "${namespace}" | grep prometheus | awk '{print $1}'); do kubectl delete svc "$i" -n "${namespace}"; done
for i in $(kubectl get svc -n kube-system | grep prometheus | awk '{print $1}'); do kubectl delete svc "$i" -n kube-system; done
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io prometheus-prometheus-oper-admission
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io prometheus-prometheus-oper-admission