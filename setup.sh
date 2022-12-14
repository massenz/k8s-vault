#!/usr/bin/env zsh
#
# Created M. Massenzio, 2022-11-04
#
# Based on: https://devopscube.com/vault-in-kubernetes/
set -eu

declare kexec='kubectl exec vault-0 --'
declare vault="${kexec} vault"
declare serviceaccount="vault-auth"
declare kvstore="secrets"


echo "Enabling Kubernetes Authorization Policies"
eval $vault auth enable kubernetes

echo "Creating KV Store for ${kvstore}/ path"
eval $vault secrets enable -version=2 -path="${kvstore}" kv

echo "Enabling Vault server to make API calls to Kubernetes"
kube_tpc_addr=$(eval $kexec sh -c "echo \$KUBERNETES_PORT_443_TCP_ADDR")
eval $vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://${kube_tpc_addr}:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    disable_iss_validation=true


# Pods with this SA will be allowed to retrieve secrets from Vault
kubectl create serviceaccount ${serviceaccount}

# Create a policy to enable access to secrets stored
# in the KV store we just created.
#
# ALl the \\ escaping is due to the need to preserve quotes, but also
# the fact we need to still be able to use the $kvstore variable, so
# we can't use single quotes.
cmd="echo -e \"path \\\"${kvstore}/*\\\"\\\n{\\\ncapabilities = [ \\\"read\\\" ]\\\n}\\\n\" >/tmp/policy"
eval $kexec sh -c $cmd
eval $vault policy write ${kvstore}-policy /tmp/policy

eval $vault write auth/kubernetes/role/app \
    bound_service_account_names=${serviceaccount} \
    bound_service_account_namespaces=default \
    policies=${kvstore}-policy \
    ttl=72h

echo "Enabled the ${kvstore}-policy Policy in Vault:"
eval $vault policy read ${kvstore}-policy
