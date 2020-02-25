# App Mesh Controller

App Mesh controller Helm chart for Kubernetes

## Prerequisites

* Kubernetes >= 1.13
* IAM policies

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "appmesh:*",
                "servicediscovery:CreateService",
                "servicediscovery:GetService",
                "servicediscovery:RegisterInstance",
                "servicediscovery:DeregisterInstance",
                "servicediscovery:ListInstances",
                "servicediscovery:ListNamespaces",
                "servicediscovery:ListServices",
                "route53:GetHealthCheck",
                "route53:CreateHealthCheck",
                "route53:UpdateHealthCheck",
                "route53:ChangeResourceRecordSets",
                "route53:DeleteHealthCheck"
            ],
            "Resource": "*"
        }
    ]
}
```

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install the App Mesh CRDs:

```sh
kubectl apply -k github.com/aws/eks-charts/stable/appmesh-controller//crds?ref=master
```

Install the App Mesh CRD controller:

### Regular Kubernetes distribution

```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

### EKS on Fargate

```
export CLUSTER_NAME=<eks-cluster-name>
export AWS_REGION=<aws-region e.g. us-east-1>
```

Create namespace
```sh
kubectl create ns appmesh-system
```

Setup fargate-profile
```sh
eksctl create fargateprofile --cluster $CLUSTER_NAME --namespace appmesh-system
```

Enable IAM OIDC provider
```sh
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION --cluster=$CLUSTER_NAME --approve
```

Create IRSA for appmesh-controller
```sh
eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
        --namespace appmesh-system \
        --name appmesh-controller \
        --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
        --override-existing-serviceaccounts \
        --approve
```

Deploy appmesh-controller
```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller
```

### EKS with IAM Roles for Service Account

```
export CLUSTER_NAME=<eks-cluster-name>
export AWS_REGION=<aws-region e.g. us-east-1>
```

Create namespace
```sh
kubectl create ns appmesh-system
```

Create IRSA for appmesh-controller
```sh
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION \
    --cluster=$CLUSTER_NAME \
    --approve

eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
    --override-existing-serviceaccounts \
    --approve
```

Deploy appmesh-controller
```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller
```

## Uninstalling the Chart

To uninstall/delete the `appmesh-controller` deployment:

```console
$ helm delete --purge appmesh-controller
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | ` 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/app-mesh-controller`
`image.tag` | image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`log.level` | controller log level, possible values are `info` and `debug`  | `info`
`resources.requests/cpu` | pod CPU request | `100m`
`resources.requests/memory` | pod memory request | `64Mi`
`resources.limits/cpu` | pod CPU limit | `2000m`
`resources.limits/memory` | pod memory limit | `1Gi`
`affinity` | node/pod affinities | None
`nodeSelector` | node labels for pod assignment | `{}`
`podAnnotations` | annotations to add to each pod | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.create` | if `true`, create and use RBAC resources | `true`
`rbac.pspEnabled` | If `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | None
