# Calico on Amazon EKS

This chart installs Calico on Amazon EKS: https://docs.aws.amazon.com/eks/latest/userguide/calico.html

## Prerequisites

- Kubernetes 1.11+ running on AWS

## Installing the Chart

First add the EKS repository to Helm:

```shell
helm repo add eks https://aws.github.io/eks-charts
```

To install the chart with the release name `aws-calico` and default configuration:

```shell
$ helm install --name aws-calico --namespace kube-system eks/aws-calico
```

To install into an EKS cluster where the CNI is already installed, you can run:

```shell
helm upgrade --install --recreate-pods --force aws-calico --namespace kube-system eks/aws-calico
```

If you receive an error similar to `Error: release aws-calico failed: <resource> "aws-node" already exists`, simply rerun the above command.

## Configuration

The following table lists the configurable parameters for this chart and their default values.

| Parameter               | Description                                             | Default            |
| ------------------------|---------------------------------------------------------|--------------  ----|
| `calico.typha.image`    | Calico Typha Image                                      | ``                 |
| `calico.node.image`     | Calico Node Image                                       | ``                 |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file containing the values for the above parameters:

```shell
$ helm install --name aws-calico --namespace kube-system eks/aws-calico --values values.yaml
```