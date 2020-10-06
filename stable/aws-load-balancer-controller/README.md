# AWS Load Balancer Controller

AWS Load Balancer controller Helm chart for Kubernetes

## TL;DR:
```sh
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master
helm install eks/aws-load-balancer-controller
```

## Introduction
AWS Load Balancer controller manages the following AWS resources
- Application Load Balancers to satisfy Kubernetes ingress objects
- Network Load Balancers in IP mode to satisfy Kubernetes service objects of type LoadBalancer with NLB IP mode annotation

## Prerequisites
- Kubernetes 1.9+ for ALB, 1.20+ for NLB IP mode
- IAM permissions

IAM permissions are required for the controller to access the AWS ALB/NLB resources. The following permissions are required at the minimum
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebAcl"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:GetServerCertificate",
        "iam:ListServerCertificates"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cognito-idp:DescribeUserPoolClient"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf-regional:GetWebACLForResource",
        "waf-regional:GetWebACL",
        "waf-regional:AssociateWebACL",
        "waf-regional:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "tag:GetResources",
        "tag:TagResources"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf:GetWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "wafv2:GetWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "shield:DescribeProtection",
        "shield:GetSubscriptionState",
        "shield:DeleteProtection",
        "shield:CreateProtection",
        "shield:DescribeSubscription",
        "shield:ListProtections"
      ],
      "Resource": "*"
    }
  ]
}
```

## Installing the Chart
**Note**: You need to uninstall aws-alb-ingress-controller. Please refer to the [upgrade](#Upgrade) section below before you proceed.

Add the EKS repository to Helm:
```shell script
helm repo add eks https://aws.github.io/eks-charts
```

Install the TargetGroupBinding CRDs:

```shell script
kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master
```

Install the AWS Load Balancer controller
```shell script
# NOTE: The clusterName value must be set either via the values.yaml or the Helm command line. The <k8s-cluster-name> in the command
# below should be replaced with name of your k8s cluster before running it.
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<k8s-cluster-name>
```

## Upgrade
The new controller is backwards compatible with the existing ingress objects. However, it will not coexist with the older aws-alb-ingress-controller.
The old controller must be uninstalled completely before installing the new version.
### Kubectl installation
If previous version was installed via kubectl, uninstall as follows
```shell script
$ kubectl delete deployment -n kube-system alb-ingress-controller
# Find the version of the current controller
$ kubectl describe deployment  -n kube-system  alb-ingress-controller |grep Image
      Image:      docker.io/amazon/aws-alb-ingress-controller:v1.1.8
# In this case, the version is v1.1.8, the rbac roles can be removed as follows
$ kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.8/docs/examples/rbac-role.yaml
```
### Helm installation
If incubator/aws-alb-ingress-controller Helm chart was installed, uninstall as follows
```shell script
# NOTE: If installed under a different chart name and namespace, please specify as appropriate
$ helm delete aws-alb-ingress-controller -n kube-system
```


## Uninstalling the Chart
```sh
helm delete aws-load-balancer-controller -n kube-system
```

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

| Parameter                         | Description                                               | Default                                                                                   |
| ----------------------------------| --------------------------------------------------------- | ------------------------------------------------------------------------------------------|
| `image.repository`                | image repository                                          | `amazon/aws-load-balancer-controller`        						    |
| `image.tag`                       | image tag                                                 | `<VERSION>`                                                                               |
| `image.pullPolicy`                | image pull policy                                         | `IfNotPresent`                                                                            |
| `clusterName`                     | Kubernetes cluster name                                   | None                                                                                      |
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

