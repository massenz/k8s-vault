#!/usr/bin/env sh
set -eu

echo "Initializing Vault"
vault operator init -key-shares=1 -key-threshold=1 -format=json > /vault/keys.json

# FIXME: the vault container does not have jq and apt is not available
VAULT_UNSEAL_KEY=$(cat /vault/keys.json | jq -r ".unseal_keys_b64[0]")
VAULT_ROOT_KEY=$(cat /vault/keys.json | jq -r ".root_token")

echo "Unsealing Vault"
vault operator unseal $VAULT_UNSEAL_KEY
VAULT_TOKEN=$(vault login $VAULT_ROOT_KEY | egrep "^token\s" | awk '{print $2}')

echo "To login to Vault UI use http://localhost:32000 and Token: ${VAULT_TOKEN}"
