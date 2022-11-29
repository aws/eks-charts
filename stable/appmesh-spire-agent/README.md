# Sample App Mesh SPIRE Agent

Sample App Mesh SPIRE Agent Helm chart for Kubernetes

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install App Mesh SPIRE Agent:

```sh
helm upgrade -i appmesh-spire-agent eks/appmesh-spire-agent \
--namespace spire
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `appmesh-spire-agent` deployment:

```console
helm delete appmesh-spire-agent --namespace spire
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`config.trustDomain` | SPIRE Trust Domain | `appmesh.aws`
`config.logLevel` | Log Level | `DEBUG`
`config.serverAddress` | SPIRE Server Address | `spire-server`
`config.serverPort` | SPIRE Server Bind Port | `8081`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | `spire-agent`
`image.tag` | SPIRE Server image version | `1.5.0`

If you want to upgrade existing SPIRE to a later version without down time, be aware that the difference between SPIRE Agent and SPIRE Server CANNOT BE GREATER than 1 minor version. Also you have to upgrade 1 minor version at a time. Check this [documentation](https://github.com/spiffe/spire/blob/main/doc/upgrading.md) for more info.