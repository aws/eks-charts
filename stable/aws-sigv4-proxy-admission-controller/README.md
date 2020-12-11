# AWS SIGv4 Admission Controller

A helm chart for [AWS SIGv4 Admission Controller](https://github.com/aws-observability/aws-sigv4-proxy-admission-controller)

## Installing the Chart

Add the EKS repository to Helm:

```bash
helm repo add eks https://aws.github.io/eks-charts
```

Install or upgrading the AWS SIGv4 Admission Controller chart with default configuration:

```bash
helm upgrade --install aws-sigv4-proxy --namespace <namespace>
```

## Uninstalling the Chart

To uninstall/delete the `aws-sigv4-proxy` release:

```bash
helm delete aws-sigv4-proxy --namespace <namespace>
```

## Configuration

| Parameter | Description | Default | Required |
| - | - | - | -
| `name` | Name of chart | `sidecar-injector` | ✔
| `image.uri` | URI of image to deploy | `public.ecr.aws/aws-observability/aws-sigv4-proxy-admission-controller:1.0` | ✔
| `image.pullPolicy` | Pull policy for the image | `IfNotPresent` | ✔
| `env.awsSigV4ProxyImage` | AWS SIGv4 image to use as sidecar | `public.ecr.aws/aws-observability/aws-sigv4-proxy:1.0` | ✔
| `serviceAccount.create` | Whether a new service account should be created | `true` |
| `serviceAccount.name` | Name of the service account | `""` |
| `service.port` | Incoming port | `443` |
| `service.targetPort` | Target port | `443` |