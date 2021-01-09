# AWS SIGv4 Admission Controller

A helm chart for [AWS SIGv4 Admission Controller](https://github.com/aws-observability/aws-sigv4-proxy-admission-controller)

## Installing the Chart

Add the EKS repository to Helm:

```bash
helm repo add eks https://aws.github.io/eks-charts
```

Install the AWS SIGv4 Admission Controller chart with default configuration:

```bash
helm install aws-sigv4-proxy-admission-controller eks/aws-sigv4-proxy-admission-controller --namespace <namespace>
```

## Uninstalling the Chart

To uninstall/delete the `aws-sigv4-proxy-admission-controller` release:

```bash
helm uninstall aws-sigv4-proxy-admission-controller --namespace <namespace>
```

## Configuration

| Parameter | Description | Default
| - | - | -
| `nameOverride` | Used to override name of chart | `""`
| `fullnameOverride` | Used to override the full name of the application | `""`
| `replicaCount` | Number of replicas | `1`
| `image.repository` | Repository of image to pull for deployment | `public.ecr.aws/aws-observability/aws-sigv4-proxy-admission-controller`
| `image.tag` | Tag of image to pull from repository | `1.0`
| `image.pullPolicy` | Policy of how to pull image | `IfNotPresent`
| `env.awsSigV4ProxyImage` | Image URI of sidecar container for AWS SIGv4 Proxy | `public.ecr.aws/aws-observability/aws-sigv4-proxy:1.0`
| `serviceAccount.create` | Whether to create a service account or not | `true`
| `serviceAccount.name` | The name of the service account to create or use | `""`
| `rbac.create` | Whether to create rbac resources or not | `true`
| `webhookService.port` | Incoming port used by webhook service | `443`
| `webhookService.targetPort` | Target port used by webhook service | `443`