#!/usr/bin/env zsh
#
# Deploys Vault to kubernetes
# Created M. Massenzio, 2022-10-22

set -eu

kubectl apply -f vault-manifests/rbac.yaml
kubectl apply -f vault-manifests/configmap.yaml
kubectl apply -f vault-manifests/services.yaml
kubectl apply -f vault-manifests/statefulset.yaml

declare STATUS=""
while [[ $STATUS != "Running" ]]; do
    STATUS=$(kubectl get pods | egrep "^vault-0\s" | awk '{print $3}')
    echo "Waiting for Vault Pod to start ($STATUS)..."
    sleep 3
done

kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > keys.json
bat keys.json

VAULT_UNSEAL_KEY=$(cat keys.json | jq -r ".unseal_keys_b64[]")
VAULT_ROOT_KEY=$(cat keys.json | jq -r ".root_token")

echo "Unsealing Vault"
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
VAULT_TOKEN=$(kubectl exec vault-0 -- vault login $VAULT_ROOT_KEY | egrep "^token\s" | awk '{print $2}')

echo "To login to Vault UI use http://localhost:32000 and Token: ${VAULT_TOKEN}"

if [[ $(uname -s) == "Darwin" ]]
then
    open http://localhost:32000
elif [[ $(uname -s) == "Linux" ]]
then
    xdg-open http://localhost:32000
fi
