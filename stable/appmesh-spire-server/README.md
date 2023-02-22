# Sample App Mesh SPIRE Server

Sample App Mesh SPIRE Server Helm chart for Kubernetes

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install App Mesh SPIRE Server:

```sh
helm upgrade -i appmesh-spire-server eks/appmesh-spire-server \
--namespace spire
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## SPIRE Controller Manager

If you would like the SPIRE Server to dynamically register workloads within your cluster, install the following CRDs:

```sh
kubectl apply -f https://raw.githubusercontent.com/spiffe/spire-controller-manager/main/config/crd/bases/spire.spiffe.io_clusterfederatedtrustdomains.yaml
kubectl apply -f https://raw.githubusercontent.com/spiffe/spire-controller-manager/main/config/crd/bases/spire.spiffe.io_clusterspiffeids.yaml
```
Reference the [spire-controller-manager documentation](https://github.com/spiffe/spire-controller-manager) to learn more. In order to control which workloads the controller manager registers, either add additional namespaces to the `spireControllerManager.ignoreNamespaces` list or deploy a [Cluster SPIFFE ID resource](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) to instruct the controller manager which pods to target for registering workloads.


## Uninstalling the Chart

To uninstall/delete the `appmesh-spire-server` deployment:

```console
helm delete appmesh-spire-server --namespace spire
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`config.trustDomain` | SPIRE Trust Domain | `appmesh.aws`
`config.clusterName` | Cluster Name | `k8s-cluster`
`config.logLevel` | Log Level | `DEBUG`
`config.svidTTL` | SVID TTL value | `1h`
`config.bindAddress` | SPIRE Server Bind Address | `0.0.0.0`
`config.bindPort` | SPIRE Server Bind Port | `8081`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | `spire-server`
`config.plugin`| SPIRE Plugin(s) | `null`
`image.tag` | SPIRE Server image version | `1.5.0`
`spireControllerManager.enabled` | Enable SPIRE Controller Manager | `false`
`spireControllerManager.ignoreNamespaces` | List of namespaces for the SPIRE Controller Manager to ignore | `[kube-system, kube-public, spire]`


To add plugins to the SPIRE server according to the [documentation](https://spiffe.io/docs/latest/planning/extending/), use the following convention
``` yaml
config:
    plugin: |
        NodeAttestor "tpm" {
            plugin_cmd = "/path/to/plugin_cmd"
            plugin_checksum = "sha256 of the plugin binary"
            plugin_data {
                ca_path = "/opt/spire/.data/certs"
            }
        }       
```

If you want to upgrade existing SPIRE to a later version without down time, be aware that the difference between SPIRE Agent and SPIRE Server CANNOT BE GREATER than 1 minor version. Also you have to upgrade 1 minor version at a time. Check this [documentation](https://github.com/spiffe/spire/blob/main/doc/upgrading.md) for more info.
