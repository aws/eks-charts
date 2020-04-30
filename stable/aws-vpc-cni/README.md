# AWS VPC CNI

This chart installs the AWS CNI Daemonset: https://github.com/aws/amazon-vpc-cni-k8s

## Prerequisites

- Kubernetes 1.11+ running on AWS

## Installing the Chart

First add the EKS repository to Helm:

```shell
helm repo add eks https://aws.github.io/eks-charts
```

To install the chart with the release name `aws-vpc-cni` and default configuration:

```shell
$ helm install --name aws-vpc-cni --namespace kube-system eks/aws-vpc-cni
```

To install into an EKS cluster where the CNI is already installed, you can run:

```shell
helm upgrade --install --recreate-pods --force aws-vpc-cni --namespace kube-system eks/aws-vpc-cni
```

If you receive an error similar to `Error: release aws-vpc-cni failed: <resource> "aws-node" already exists`, simply rerun the above command.

## Configuration

The following table lists the configurable parameters for this chart and their default values.

| Parameter               | Description                                             | Default                             |
| ------------------------|---------------------------------------------------------|-------------------------------------|
| `affinity`              | Map of node/pod affinities                              | `{}`                                |
| `env`                   | List of environment variables. See [here](https://github.com/aws/amazon-vpc-cni-k8s#cni-configuration-variables) for options     | `[AWS_VPC_K8S_CNI_LOGLEVEL: DEBUG, AWS_VPC_K8S_CNI_VETHPREFIX: eni, AWS_VPC_ENI_MTU: "9001"]` |
| `fullnameOverride`      | Override the fullname of the chart                      | `aws-node`                          |
| `image.region`          | ECR repository region to use. Should match your cluster | `us-west-2`                         |
| `image.tag`             | Image tag                                               | `v1.6.1`                            |
| `image.pullPolicy`      | Container pull policy                                   | `IfNotPresent`                      |
| `image.override`        | A custom docker image to use                            | `nil`                               |
| `imagePullSecrets`      | Docker registry pull secret                             | `[]`                                |
| `nameOverride`          | Override the name of the chart                          | `aws-node`                          |
| `nodeSelector`          | Node labels for pod assignment                          | `{}`                                |
| `podSecurityContext`    | Pod Security Context                                    | `{}`                                |
| `podAnnotations`        | annotations to add to each pod                          | `{}`                                |
| `priorityClassName`     | Name of the priorityClass                               | `system-node-critical`              |
| `resources`             | Resources for the pods                                  | `requests.cpu: 10m`                 |
| `securityContext`       | Container Security context                              | `privileged: true`                  |
| `serviceAccount.name`   | The name of the ServiceAccount to use                   | `nil`                               |
| `serviceAccount.create` | Specifies whether a ServiceAccount should be created    | `true`                              |
| `serviceAccount.annotations` | Specifies the annotations for ServiceAccount       | `{}`                                |
| `tolerations`           | Optional deployment tolerations                         | `[]`                                |
| `updateStrategy`        | Optional update strategy                                | `type: RollingUpdate`               |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file containing the values for the above parameters:

```shell
$ helm install --name aws-vpc-cni --namespace kube-system eks/aws-vpc-cni --values values.yaml
```
