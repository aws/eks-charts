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
`config.logLevel` | Log Level | `DEBUG`
`config.svidTTL` | SVID TTL value | `1h`
`config.bindAddress` | SPIRE Server Bind Address | `0.0.0.0`
`config.bindPort` | SPIRE Server Bind Port | `8081`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | `spire-server`
`config.plugin`| SPIRE Plugin(s) | `null`


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
