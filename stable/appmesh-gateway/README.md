# App Mesh Gateway

App Mesh Gateway Helm chart for Kubernetes

## Prerequisites

* App Mesh CRDs
* App Mesh Manager >= 1.0.0

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Create a namespace with injection enabled:

```sh
kubectl create ns appmesh-ingress
kubectl label namespace appmesh-ingress appmesh.k8s.aws/sidecarInjectorWebhook=enabled
```

Deploy the App Mesh Gateway in the `appmesh-ingress` namespace:

```sh
helm upgrade -i appmesh-gateway eks/appmesh-gateway \
--namespace appmesh-ingress
```

Find the NLB address:

```sh
kubectl get svc appmesh-gateway -n appmesh-ingress
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `appmesh-gateway` deployment:

```console
$ helm delete appmesh-gateway -n appmesh-ingress
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy`
`image.tag` | image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`service.type` | service type  | `LoadBalancer`
`service.port` | service port  | `80`
`service.annotations` | service annotations | NLB load balancer type
`service.externalTrafficPolicy` | when set to `Local` it preserves the client source IP  | `Cluster`
`appmesh.gateway` | create a `VirtualGateway` object  | `true`
`appmesh.preview` | enable App Mesh Preview (us-west-2 only)  | `false`
`resources.requests/cpu` | pod CPU request | `100m`
`resources.requests/memory` | pod memory request | `64Mi`
`podAntiAffinity` | soft pod anti-affinity, one replica per node | `true`
`nodeSelector` | node labels for pod assignment | `{}`
`podAnnotations` | annotations to add to each pod | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.pspEnabled` | If `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | None
