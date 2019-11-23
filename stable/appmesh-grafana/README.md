# App Mesh Grafana

App Mesh Grafana Helm chart for Kubernetes

## Prerequisites

* Kubernetes >= 1.13
* AWS App Mesh [Prometheus](https://github.com/aws/eks-charts/tree/master/stable/appmesh-prometheus) >= 0.3.0

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install App Mesh Grafana:

```sh
helm upgrade -i appmesh-grafana eks/appmesh-grafana \
--namespace appmesh-system
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `appmesh-grafana` deployment:

```console
helm delete --purge appmesh-grafana
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | `grafana/grafana`
`image.tag` | image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`resources.requests/cpu` | pod CPU request | `100m`
`resources.requests/memory` | pod memory request | `256Mi`
`resources.limits/cpu` | pod CPU limit | `2000m`
`resources.limits/memory` | pod memory limit | `2Gi`
`affinity` | node/pod affinities | None
`nodeSelector` | node labels for pod assignment | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.pspEnabled` | If `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | None
`url` |  Prometheus URL | `http://appmesh-prometheus:9090`
