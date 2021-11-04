# Calico on AWS

This chart installs Calico Operator on AWS: https://docs.aws.amazon.com/eks/latest/userguide/calico.html

## Prerequisites

- Kubernetes 1.11+ running on AWS

## Installing the Chart

First add the EKS repository to Helm:

```shell script
helm repo add eks https://aws.github.io/eks-charts
```

Install the Tigera Operator charts with the release name `aws-tigera-operator` and default configuration:
```shell script
helm install aws-tigera-operator eks/aws-tigera-operator
```
To install into an EKS cluster where the CNI is already installed, you can run:
```shell script
helm upgrade --install --recreate-pods --force aws-tigera-operator eks/aws-tigera-operator
```
Note:
- The Tigera operator installs Calico CRDs.
- The Tigera operator installs resources in the calico-system namespace. Previous aws-calico install methods use the kube-system namespace instead.

## Configuration
The configurable parameters can be configured in `Installation`. Please refer to [Tigera Operator Installation document](https://docs.tigera.io/reference/installation/api#operator.tigera.io/v1.InstallationSpec) for
details.

Alternatively, provided `values.yaml` contains the Installation where the parameters can be configured:

```shell script
$ helm install aws-tigera-operator eks/aws-tigera-operator --values values.yaml
```
