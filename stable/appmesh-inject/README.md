# App Mesh Inject

App Mesh inject Helm chart for Kubernetes

## Prerequisites

* Kubernetes >= 1.13

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install the App Mesh CRDs:

```sh
kubectl apply -k github.com/aws/eks-charts/stable/appmesh-controller//crds?ref=master
```

Install the App Mesh admission controller:

```sh
helm upgrade -i appmesh-inject eks/appmesh-inject \
--namespace appmesh-system \
--set mesh.name=global
```

Optionally you can create a mesh at install time:
  
```sh
helm upgrade -i appmesh-inject eks/appmesh-inject \
--namespace appmesh-system \
--set mesh.name=global \
--set mesh.create=true
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `appmesh-inject` deployment:

```console
helm delete --purge appmesh-inject
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | controller image repository | `602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-app-mesh-inject`
`image.tag` | controller image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`resources.requests/cpu` | pod CPU request | `100m`
`resources.requests/memory` | pod memory request | `64Mi`
`resources.limits/cpu` | pod CPU limit | `2000m`
`resources.limits/memory` | pod memory limit | `1Gi`
`affinity` | node/pod affinities | None
`nodeSelector` | node labels for pod assignment | `{}`
`podAnnotations` | annotations to add to each pod | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.create` | if `true`, create and use RBAC resources | `true`
`rbac.pspEnabled` | If `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | None
`sidecar.image.repository` | Envoy image repository | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy`
`sidecar.image.tag` | Envoy image tag | `<VERSION>`
`sidecar.logLevel` | Envoy log level | `info`
`sidecar.resources` | Envoy container resources | `requests: cpu 10m memory 32Mi`
`init.image.repository` | Route manager image repository | `111345817488.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-proxy-route-manager`
`init.image.tag` | Route manager image tag | `<VERSION>`
`mesh.create` | If `true`, create mesh custom resource | `false`
`mesh.name` | The name of the mesh to use | `global`
`mesh.discovery` | The service discovery type to use, can be dns or cloudmap | `dns`
`tracing.enabled` |  If `true`, Envoy will be configured with tracing | `false`
`tracing.provider` |  The tracing provider can be x-ray, jaeger or datadog | `x-ray`
`tracing.address` |  Jaeger or Datadog agent server address (ignored for X-Ray) | `appmesh-jaeger.appmesh-system`
`tracing.port` |  Jaeger or Datadog agent port (ignored for X-Ray) | `9411`
