# kubernetes-vault

*Kubernetes manifests to setup Hashicorp vault server*

[Full Documentation](https://devopscube.com/vault-in-kubernetes/)

## Deploy & Configure

Use the following scripts to deploy the necessary kubernetes resources and initialize Vault:

```
./deploy.sh
./setup.sh
```

the configuration and auth tokens will be saved to `keys.json`.

## Test access

Clone the [`k8s-web-config`](https://github.com/massenz/k8s-web-config) repository, and run the `utils` Pod:

```
kubectl apply -f spect/utils.yaml
```

from the pod, run a POST command:

```
kubectl exec -it utils -- /bin/bash

root@utils:/# jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
root@utils:/# http  --json vault:8200/v1/auth/kubernetes/login jwt="$jwt" role=app
```

To retrieve secrets, you will need the `client_token`:

```
root@utils:/# client_token=$(http --json vault:8200/v1/auth/kubernetes/login jwt="$jwt" role=app | \
    jq -r ".auth.client_token")

root@utils:/# http vault:8200/v1/secrets/data/app/test/secret \
    X-Vault-Token:${client_token} \
    X-Vault-Namespace:vault
```

Note the format of the `vault` URL (this is for [`KVv2` stores](https://developer.hashicorp.com/vault/api-docs/secret/kv/kv-v2#sample-request-3)),
inserts a `data` segment between the name of the store (`secrets`) and the path to the secret (`app/test/secret`).

The JSON contains also the metadata, while the secrets are in the `data.data` object:

```json
{
    "auth": null,
    "data": {
        "data": {
            "my-key": "my-secret-value"
        },
        "metadata": {
            "created_time": "2022-11-05T04:40:22.650374677Z",
            "deletion_time": "",
            "destroyed": false,
            "version": 1
        }
    },
    "lease_duration": 0,
    "lease_id": "",
    "renewable": false,
    "request_id": "60a82341-bbfa-d4e8-4564-e77c634f7aaf",
    "warnings": null,
    "wrap_info": null
}
```
