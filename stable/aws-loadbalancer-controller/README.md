# AWS Loadbalancer Controller

AWS Loadbalancer controller Helm chart for Kubernetes

## TL;DR:
```sh
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k github.com/aws/eks-charts/stable/aws-loadbalancer-controller//crds?ref=master
helm install eks/aws-loadbalancer-controller
```

## Introduction
AWS Loadbalancer controller manages the following AWS resources
- Application Load Balancers to satisfy Kubernetes ingress objects
- Network Load Balancers in IP mode to satisfy Kubernetes service objects of type LoadBalancer with NLB IP mode annotation

## Prerequisites
- Kubernetes 1.9+ for ALB, 1.20+ for NLB IP mode
- IAM permissions

## Installing the Chart
**Note**: You need to uninstall aws-alb-ingress-controller

Add the EKS repository to Helm:
```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install the TargetGroupBinding CRDs:

```sh
kubectl apply -k github.com/aws/eks-charts/stable/aws-loadbalancer-controller//crds?ref=master
```

Install the AWS Loadbalancer controller
```sh
helm upgrade -i aws-loadbalancer-controller eks/aws-loadbalancer-controller -n kube-system
```

## Uninstalling the Chart
```sh
helm delete aws-loadbalancer-controller -n kube-system
```

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

| Parameter                         | Description                                               | Default                                                                                   |
| ----------------------------------| --------------------------------------------------------- | ------------------------------------------------------------------------------------------|
| `image.repository`                | image repository                                          | ` 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-loadbalancer-controller`        |
| `image.tag`                       | image tag                                                 | `<VERSION>`                                                                               |
| `image.pullPolicy`                | image pull policy                                         | `IfNotPresent`                                                                            |
| `securityContext`                 | Set to security context for pod                           | `{}`                                                                                      |
| `resources`                       | Controller pod resource requests & limits                 | `{}`                                                                                      |
| `nodeSelector`                    | Node labels for controller pod assignment                 | `{}`                                                                                      |
| `tolerations`                     | Controller pod toleration for taints                      | `{}`                                                                                      |
| `affinity`                        | Affinity for pod assignment                               | `{}`                                                                                      |
| `rbac.create`                     | if `true`, create and use RBAC resources                  | `true`                                                                                    |
| `serviceAccount.annotations`      | optional annotations to add to service account            | None                                                                                      |
| `serviceAccount.create`           | If `true`, create a new service account                   | `true`                                                                                    |
| `serviceAccount.name`             | Service account to be used                                | None                                                                                      |
| `terminationGracePeriodSeconds`   | Time period for controller pod to do a graceful shutdown  | 10                                                                                        |

