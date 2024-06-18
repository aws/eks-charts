# EKS Pod Identity Agent

This chart installs the [eks-pod-identity-agent](https://github.com/aws/eks-pod-identity-agent).

This agent is required for EKS pods to get granular IAM permissions with EKS Pod Identity feature.

## Prerequisites

- Kubernetes v{?} running on AWS
- Helm v3

## Update below Env to your cluster and region in values.yaml

* `EKS_CLUSTER_NAME` 
* `AWS_REGION_NAME`

## Installing the Chart

First, add the EKS repository to Helm:

```
helm repo add eks https://aws.github.io/eks-charts
```

To install the chart with the release name of `eks-pod-identity-agent` and default configuration:

```
helm install eks-pod-identity-agent --namespace kube-system eks/eks-pod-identity-agent
```

## Configuration

The following table lists the configurable parameters for this chart and their default values.

| Parameter                 | Description                                             | Default                  |
|---------------------------|---------------------------------------------------------|--------------------------|
| `affinity`                | Map of node/pod affinities                              | (see `values.yaml`)      |
| `agent.additionalArgs`    | Additional arguments to pass to the agent-container     | (see `values.yaml`)      |
| `env`                     | List of environment variables.                          | (see `values.yaml`)      |
| `fullnameOverride`        | Override the fullname of the chart                      | `eks-pod-identity-agent` |
| `image.pullPolicy`        | Container pull policy                                   | `Always`                 |
| `imagePullSecrets`        | Docker registry pull secret                             | `[]`                     |
| `init.additionalArgs`     | Additional arguments to pass to the init-container      | (see `values.yaml`)      |
| `init.create`             | Specifies whether init-container should be created      | `true`                   |
| `nameOverride`            | Override the name of the chart                          | `eks-pod-identity-agent` |
| `nodeSelector`            | Node labels for pod assignment                          | `{}`                     |
| `podAnnotations`          | annotations to add to each pod                          | `{}`                     |
| `priorityClassName`       | Name of the priorityClass                               | `system-node-critical`   |
| `resources`               | Resources for containers in pod                         | `{}`                     |
| `tolerations`             | Optional deployment tolerations                         | `all`                    |
| `updateStrategy`          | Optional update strategy                                | `type: RollingUpdate`    |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file
containing the values for the above parameters.
