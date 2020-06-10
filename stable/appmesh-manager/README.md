# App Mesh Manager

App Mesh manager Helm chart for Kubernetes

## Prerequisites

Note: the current release candidate uses App Mesh preview service endpoints. It will be changed to App Mesh service at the time of GA release.
Two important things when using App Mesh preview:
1. When configuring IAM policies, use `appmesh-preview` as the service name instead of `appmesh`. See the example JSON below.
2. When configuring pods, add the following annotation so Envoy sidecars point to the preview as well:
```
annotations:
  appmesh.k8s.aws/preview: "true"
```

More information on App Mesh preview can be found [here](https://docs.aws.amazon.com/app-mesh/latest/userguide/preview.html)


* Kubernetes >= 1.13
* IAM policies

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "appmesh-preview:*",
                "servicediscovery:CreateService",
                "servicediscovery:DeleteService",
                "servicediscovery:GetService",
                "servicediscovery:GetInstance",
                "servicediscovery:RegisterInstance",
                "servicediscovery:DeregisterInstance",
                "servicediscovery:ListInstances",
                "servicediscovery:ListNamespaces",
                "servicediscovery:ListServices",
                "servicediscovery:GetOperation",
                "servicediscovery:GetInstancesHealthStatus",
                "servicediscovery:UpdateInstanceCustomHealthStatus",
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
kubectl apply -k github.com/aws/eks-charts/stable/appmesh-manager//crds?ref=master
```

Install the App Mesh CRD controller:

### Regular Kubernetes distribution

Create namespace
```sh
kubectl create ns appmesh-system
```

Deploy appmesh-manager
```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
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

Create IRSA for appmesh-manager
```sh
eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
        --namespace appmesh-system \
        --name appmesh-manager \
        --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
        --override-existing-serviceaccounts \
        --approve
```

Deploy appmesh-manager
```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-manager
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

Create IRSA for appmesh-manager
```sh
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION \
    --cluster=$CLUSTER_NAME \
    --approve

eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-manager \
    --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
    --override-existing-serviceaccounts \
    --approve
```

Deploy appmesh-manager
```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-manager
```

## Uninstalling the Chart

To uninstall/delete the `appmesh-manager` deployment:

```console
$ helm delete appmesh-manager -n appmesh-system
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | ` 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/app-mesh-manager`
`image.tag` | image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`log.level` | manager log level, possible values are `info` and `debug`  | `info`
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
`sidecar.image.repository` | Envoy image repository | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy`
`sidecar.image.tag` | Envoy image tag | `<VERSION>`
`sidecar.logLevel` | Envoy log level | `info`
`sidecar.resources` | Envoy container resources | `requests: cpu 10m memory 32Mi`
`init.image.repository` | Route manager image repository | `111345817488.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-proxy-route-manager`
`init.image.tag` | Route manager image tag | `<VERSION>`
`tracing.enabled` |  If `true`, Envoy will be configured with tracing | `false`
`tracing.provider` |  The tracing provider can be x-ray, jaeger or datadog | `x-ray`
`tracing.address` |  Jaeger or Datadog agent server address (ignored for X-Ray) | `appmesh-jaeger.appmesh-system`
`tracing.port` |  Jaeger or Datadog agent port (ignored for X-Ray) | `9411`
`enableCertManager` |  Enable Cert-Manager | `false`
