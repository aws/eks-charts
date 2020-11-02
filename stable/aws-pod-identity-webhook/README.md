# AWS Pod Identity Webhook

This chart will install the [Amazon EKS Pod Identity Webhook](https://github.com/aws/amazon-eks-pod-identity-webhook). This tool allows you to specify IAM Roles for Kubernetes Service Accounts. This allows a pod to assume a IAM role.

Further details can be found here: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-technical-overview.html

## Prerequisites

- Kubernetes 1.12+

For installation into a non-EKS cluster, see [Self-hosted Kubernetes setup](https://github.com/aws/amazon-eks-pod-identity-webhook/blob/master/SELF_HOSTED_SETUP.md)

## Installing the Chart

You first need to retrieve `ca.crt` from your cluster as this is used as a value for the chart:

```sh
secret_name=$(kubectl get sa default -o jsonpath='{.secrets[0].name}')
export CA_BUNDLE=$(kubectl get secret/$secret_name -o jsonpath='{.data.ca\.crt}' | tr -d '\n')
```

And add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Then install the chart:

```sh
helm upgrade -i pod-identity-webhook eks/aws-pod-identity-webhook \
--namespace kube-system --set caBundle="${CA_BUNDLE}"
```

After installation you need to approve the certificate. Follow the chart notes after installation for this step.

The webhook will request a new CSR prior to expiration. This new CSR will also need to be manually approved.

## Uninstalling the Chart

To delete the chart:

```sh
helm delete --purge pod-identity-webhook
```

## Configuration

The following table lists the configurable parameters for this chart and their default values.

| Parameter                   | Description                           | Default                                                                 |
| ----------------------------|---------------------------------------|-------------------------------------------------------------------------|
| `tlsSecretName`             | Name of the secret containing the     | `pod-identity-webhook`                                                  |
| `annotationPrefix`          | Prefix for annotation                 | `eks.amazonaws.com`                                                     |
| `tokenAudience`             | Token audience                        | `sts.amazonaws.com`                                                     |
| `caBundle`                  | CA cert bundle data                   | None. Must be provided on chart install                                 |
| `image.repository`          | Image repository                      | `amazon/amazon-eks-pod-identity-webhook`                                |
| `image.tag`                 | Image tag                             | `latest`                                                                |
| `image.pullPolicy`          | Container pull policy                 | `IfNotPresent`                                                          |
| `replicas`                  | Number of deployment replicas         | `3`                                                                     |
| `fullnameOverride`          | Override the fullname of the chart    | `nil`                                                                   |
| `nameOverride`              | Override the name of the chart        | `nil`                                                                   |
| `priorityClassName`         | Set a priority class for pods         | `nil`                                                                   |
| `resources.requests.cpu`    | pod CPU request                       | `100m`                                                                  |
| `resources.requests.memory` | pod memory request                    | `64Mi`                                                                  |
| `resources.limits.cpu`      | pod CPU limit                         | `2000m`                                                                 |
| `resources.limits.memory`   | pod memory limit                      | `1Gi`                                                                   |
| `nodeSelector`              | Node labels for pod assignment        | `{}`                                                                    |
| `tolerations`               | Optional deployment tolerations       | `[]`                                                                    |
| `affinity`                  | Map of node/pod affinities            | `{}`                                                                    |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file containing the values for the above parameters:

```sh
helm update -i pod-identity-webhook eks/aws-pod-identity-webhook --namespace kube-system --values values.yaml
```
