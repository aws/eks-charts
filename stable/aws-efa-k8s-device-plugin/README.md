# AWS EFA Kubernetes Device Plugin
This chart installs the AWS EFA Kubernetes Device Plugin daemonset with privileged security context for EFA device management and neuron instance support.

## Prerequisites
- Helm v3

## Installing the Chart
First add the EKS repository to Helm:

```shell
helm repo add eks https://aws.github.io/eks-charts
```

To install the chart with the release name `efa` in the `kube-system` namespace and default configuration:

```shell
helm install efa ./aws-efa-k8s-device-plugin -n kube-system
```

# Configuration

Parameter | Description | Default
--- | --- | ---
`image.repository` | EFA image repository | `602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efa-k8s-device-plugin`
`image.tag` | EFA image tag | `v0.5.8`
`securityContext` | EFA plugin security context | `allowPrivilegeEscalation: true, privileged: true, runAsNonRoot: false, runAsUser: 0`
`supportedInstanceLabels.keys` | Kubernetes key to interpret as instance type | `nodes.kubernetes.io/instance-type`
`supportedInstanceLabels.values` | List of instances which currently support EFA devices | `see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa.html#efa-instance-types`
`resources` | Resources for containers in pod | `requests.cpu: 10m requests.memory: 20Mi`
`nodeSelector` | Node labels for pod assignment | `{}`
`tolerations` | Optional deployment tolerations | `[]`
`additionalPodAnnotations` | Pod annotations to apply in addition to the default ones | `{}`
`additionalPodLabels` | Pod labels to apply in addition to the defualt ones | `{}`
`nameOverride` | Override the name of the chart | `""`
`fullnameOverride` | Override the full name of the chart | `""`
`imagePullSecrets` | Docker registry pull secret | `[]`

