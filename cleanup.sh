#!/usr/bin/env zsh
#
# Cleans up Vault from kubernetes
# Created M. Massenzio, 2022-10-22

set -eu

kubectl delete -f vault-manifests/statefulset.yaml
kubectl delete -f vault-manifests/services.yaml
kubectl delete -f vault-manifests/rbac.yaml
kubectl delete -f vault-manifests/configmap.yaml

kubectl delete pvc data-vault-0
rm keys.json

echo "Done: all services/configuration/data removed"
