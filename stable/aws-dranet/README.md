# aws-dranet

A Helm chart for the dranet network driver for AWS EC2 instances.

dranet is a Kubernetes DRA (Dynamic Resource Allocation) network driver that runs as a DaemonSet on every eligible node. It discovers and publishes EFA devices so that workloads can request them through the Kubernetes DRA API.

## Prerequisites

- Kubernetes 1.35+ (with DRA feature gate enabled)
- Helm 3+

## Installation

Add the EKS charts repository:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

Install the chart:

```bash
helm install aws-dranet eks/aws-dranet --namespace kube-system
```

To upgrade an existing release:

```bash
helm upgrade aws-dranet eks/aws-dranet --namespace kube-system
```

To uninstall:

```bash
helm uninstall aws-dranet --namespace kube-system
```

## Configuration

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Container image repository | `602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/dranet` |
| `image.tag` | Container image tag | `v1.2.0-eksbuild.2` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `securityContext` | Container security context | See `values.yaml` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `50Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `serviceAccount.create` | Whether to create a ServiceAccount | `true` |
| `serviceAccount.name` | Override ServiceAccount name (uses fullname if empty) | `""` |
| `tolerations` | Additional tolerations for the DaemonSet pods | `[]` |
| `nodeSelector` | Node selector for the DaemonSet pods | `{}` |
| `podAnnotations` | Additional pod annotations | `{}` |
| `podLabels` | Additional pod labels | `{}` |
| `nameOverride` | Override the chart name | `""` |
| `fullnameOverride` | Override the fully qualified name | `""` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `updateStrategy` | DaemonSet update strategy | `{}` |
| `priorityClassName` | Pod priority class | `system-node-critical` |
| `deviceClass.create` | Whether to create a default DeviceClass for EFA devices | `true` |
| `deviceClass.name` | Name of the DeviceClass | `efa.networking.k8s.aws` |
| `healthPort` | Port for the healthz/metrics server (`--bind-address` flag) | `9177` |
| `verbosity` | Log verbosity level (`--v` flag) | `4` |
| `filter` | CEL filter expression (`--filter` flag); set to `""` to disable | See `values.yaml` |
