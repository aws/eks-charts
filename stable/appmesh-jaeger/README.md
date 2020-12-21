# App Mesh Jaeger

App Mesh Jaeger Helm chart for Kubernetes

## Prerequisites

* Kubernetes >= 1.13

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install App Mesh Jaeger:

```sh
helm upgrade -i appmesh-jaeger eks/appmesh-jaeger \
--namespace appmesh-system
```

For Jaeger persistent storage you can create a [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
and use `--set persistentVolumeClaim.claimName=<PVC-CLAIM-NAME>`.

Enable Jaeger tracing for the App Mesh data plane:

```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set tracing.enabled=true \
    --set tracing.provider=jaeger \
    --set tracing.address=appmesh-jaeger.appmesh-system \
    --set tracing.port=9411
```

**Note** that you should restart all pods running inside the mesh after enabling tracing.

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `appmesh-jaeger` deployment:

```console
helm delete --purge appmesh-jaeger
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | `jaegertracing/all-in-one`
`image.tag` | image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`resources.requests/cpu` | pod CPU request | `100m`
`resources.requests/memory` | pod memory request | `256Mi`
`resources.limits/cpu` | pod CPU limit | `2000m`
`resources.limits/memory` | pod memory limit | `2Gi`
`probes.liveness.initialDelaySeconds` | seconds to delay liveness probing | `0`
`probes.liveness.periodSeconds` | interval between liveness probing | `10`
`probes.liveness.timeoutSeconds` | timeout for liveness probe  | `1`
`probes.liveness.successThreshold` | minimum consecutive successes for probe to be considered successful | `1`
`probes.liveness.failureThreshold` | minimum consecutive fails for probe to be considered failed | `3`
`probes.readiness.initialDelaySeconds` | seconds to delay readiness probing | `0`
`probes.readiness.periodSeconds` | interval between readiness probing | `10`
`probes.readiness.timeoutSeconds` | timeout for readiness probe | `1`
`probes.readiness.successThreshold` | minimum consecutive successes for probe to be considered successful | `1`
`probes.readiness.failureThreshold` | minimum consecutive fails for probe to be considered failed | `3`
`affinity` | node/pod affinities | None
`nodeSelector` | node labels for pod assignment | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.create` | if `true`, create and use RBAC resources | `true`
`rbac.pspEnabled` | If `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | None
`memory.maxTraces` | The amount of traces stored in memory | `40000`
`persistentVolumeClaim.claimName` |  Specify an existing volume claim to be used for Badger data | None
