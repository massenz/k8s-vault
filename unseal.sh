#!/usr/bin/env zsh
#
# Deploys Vault to kubernetes
# Created M. Massenzio, 2022-10-22
#
# Unsealing the Vault and extracting the token
# Before running this, install the Helm Chart:
#
#  kubectl create namespace vault
#  helm install dev-vault . --namespace vault
set -eu

if ! kubectl exec -n vault vault-0 -- vault operator init -status >/dev/null
then
    echo "Initializing Vault"
    kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > keys.json
    bat keys.json
fi

if [[ ! -e keys.json ]]
then
    echo "ERROR: No keys.json file, cannot unseal"
    exit 1
fi

VAULT_UNSEAL_KEY=$(cat keys.json | jq -r ".unseal_keys_b64[]")
VAULT_ROOT_KEY=$(cat keys.json | jq -r ".root_token")

echo "Unsealing Vault"
kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
VAULT_TOKEN=$(kubectl exec vault-0 -- vault login $VAULT_ROOT_KEY | egrep "^token\s" | awk '{print $2}')

echo "To login to Vault UI use http://localhost:32000 and Token: ${VAULT_TOKEN}"

if [[ $(uname -s) == "Darwin" ]]
then
    open http://localhost:32000
elif [[ $(uname -s) == "Linux" ]]
then
    xdg-open http://localhost:32000
fi
