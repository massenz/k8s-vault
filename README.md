# Simple Vault

*Helm Chart to install and initialize Hashicorp Vault server in Kubernetes*

[Full Documentation](https://devopscube.com/vault-in-kubernetes/)

## Deploy & Configure

This is a standard [Helm chart](https://helm.sh/docs/topics/charts/) that installs [Hashicorp Vault](https://www.vaultproject.io/) in a Kubernetes cluster (we recommend the use of [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) for local development).

Use:

```shell
 helm install sec-vault . --namespace vault
```

to install the necessary resources in the `vault` namespace (the `Release.namespace` value is used in the templates, so choosing a different one should work just fine).

**`TODO`** 
> Currently unsealing the Vault and setting up the cluster is still a manual process.
>
> See the `scripts/unseal.sh` and `setup.sh` scripts.

## Debugging

The Helm chart can be debugged using the `template` and `install --dry-run` commands:

```shell
# To view the templates' output:
helm template --debug . | less

# To inspect what happens on the cluster, without actually installing the release:
helm install --dry-run --debug test-release .
```

This chart also deploys the [`dnsutils`](https://github.com/massenz/dnsutils) [container](https://hub.docker.com/repository/docker/massenz/dnsutils), which can be accessed via `kubectl exec -it utils`; for example, from the pod, run a POST command:

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
