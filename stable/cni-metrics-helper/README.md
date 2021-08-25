# AWS VPC CNI Metrics Helper

This chart installs the AWS CNI Metrics Helper: https://github.com/aws/amazon-vpc-cni-k8s

## Prerequisites

- Kubernetes 1.11+ running on AWS

## Installing the Chart

First add the EKS repository to Helm:

```shell
helm repo add eks https://aws.github.io/eks-charts
```

To install the chart with the release name `cni-metrics-helper` and default configuration:

```shell
$ helm install --name cni-metrics-helper --namespace kube-system eks/aws-vpc-cni
```

## Configuration

The following table lists the configurable parameters for this chart and their default values.

| Parameter               | Description                                             | Default                             |
| ------------------------|---------------------------------------------------------|-------------------------------------|
| `env`                   | List of environment variables.                          | (see `values.yaml`)                 |
| `fullnameOverride`      | Override the fullname of the chart                      | `cni-metrics-helper`                |
| `image.region`          | ECR repository region to use. Should match your cluster | `us-west-2`                         |
| `image.tag`             | Image tag                                               | `v1.8.0`                            |
| `image.override`        | A custom docker image to use                            | `nil`                               |
| `nameOverride`          | Override the name of the chart                          | `cni-metrics-helper`                |
| `serviceAccount.name`   | The name of the ServiceAccount to use                   | `nil`                               |
| `serviceAccount.create` | Specifies whether a ServiceAccount should be created    | `true`                              |
| `serviceAccount.annotations` | Specifies the annotations for ServiceAccount       | `{}`                                |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file containing the values for the above parameters:

```shell
$ helm install --name cni-metrics-helper --namespace kube-system eks/aws-vpc-cni --values values.yaml
```
