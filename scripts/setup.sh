#!/usr/bin/env sh
set -eu
echo "Enabling Kubernetes Authorization Policies"
vault auth enable kubernetes

echo "Creating KV Store for secrets/ path"
vault secrets enable -version=2 -path="secrets" kv

echo "Enabling Vault server to make API calls to Kubernetes"
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://${KUBERNETES_PORT_443_TCP_ADDR}:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    disable_iss_validation=true

# Create a policy to enable access to secrets stored
# in the KV store we just created.
cat >/tmp/policy <<EOF
path "secrets/*"
{
    capabilities = [ "read" ]
}
EOF

vault policy write secrets-policy /tmp/policy
vault write auth/kubernetes/role/app \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=vault \
    policies=secrets-policy \
    ttl=72h

echo "Enabled the secretes-policy Policy in Vault:"
vault policy read secrets-policy
