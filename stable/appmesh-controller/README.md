# App Mesh Controller

App Mesh controller Helm chart for Kubernetes

**Note**: If you wish to use [App Mesh preview](https://docs.aws.amazon.com/app-mesh/latest/userguide/preview.html) features, please refer to our [preview version](https://github.com/aws/eks-charts/blob/preview/stable/appmesh-controller/README.md) instructions.

## Prerequisites

* Kubernetes >= 1.13
* EKS nodes should have the IAM permissions from the following policies: `AWSAppMeshFullAccess`, `AWSCloudMapFullAccess`

## Installing the Chart

**Note**: AppMesh controller v1.0.0+ is **backwards incompatible** with old versions(e.g. v0.5.0).
If you're running an older version of App Mesh controller, please go to the [upgrade](#upgrade) section below before you proceed. If you are unsure, please run the `appmesh-controller/upgrade/pre_upgrade_check.sh` script to check if your cluster can be upgraded

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

Create namespace
```sh
kubectl create ns appmesh-system
```

Deploy appmesh-controller
```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.


## Upgrade


### Upgrade without preserving old App Mesh resources

```sh
# Keep old App Mesh controller running, it is responsible to cleanup App Mesh resources in AWS
# Delete all existing App Mesh custom resources (CRs)
kubectl delete virtualservices --all --all-namespaces
kubectl delete virtualnodes --all --all-namespaces
kubectl delete meshes --all --all-namespaces

# Delete all existing App Mesh CRDs
kubectl delete customresourcedefinition/virtualservices.appmesh.k8s.aws
kubectl delete customresourcedefinition/virtualnodes.appmesh.k8s.aws
kubectl delete customresourcedefinition/meshes.appmesh.k8s.aws
# Note: If a CRD stuck in deletion, it means there still exists some App Mesh custom resources, please check and delete them.

# Delete App Mesh controller
helm delete appmesh-controller -n appmesh-system

# Delete App Mesh injector
helm delete appmesh-inject -n appmesh-system
```

Run the `appmesh-controller/upgrade/pre_upgrade_check.sh` script and make sure it passes before you proceed

Now you can proceed with the installation steps described above

### Upgrade preserving old App Mesh resources

```sh
# Save manifests of all existing App Mesh custom resources
kubectl get virtualservices --all-namespaces -o yaml > virtualservices.yaml
kubectl get virtualnodes --all-namespaces -o yaml > virtualnodes.yaml
kubectl get meshes --all-namespaces -o yaml > meshes.yaml

# Delete App Mesh controller, so it won’t clean up App Mesh resources in AWS while we deleting App Mesh CRs later.
helm delete appmesh-controller -n appmesh-system

# Delete App Mesh injector.
helm delete appmesh-inject -n appmesh-system

# Remove finalizers from all existing App Mesh CRs. Otherwise, you won’t be able to delete them

# To remove the finalizers, you could kubectl edit resource, and delete the finalizers attribute from the spec or run the following command to override finalizers. e.g for virtualnodes
# kubectl get virtualnodes --all-namespaces -o=jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}' | xargs -n2 sh -c 'kubectl patch virtualnode/$1 -n $0 -p '\''{"metadata":{"finalizers":null}}'\'' --type=merge'

# Alternatively, you could modify one resource at a time using
# kubectl get <RESOURCE_TYPE> <RESOURCE_NAME> -n <NAMESPACE> -o=json | jq '.metadata.finalizers = null' | kubectl apply -f -

# Delete all existing App Mesh CRs:
kubectl delete virtualservices --all --all-namespaces
kubectl delete virtualnodes --all --all-namespaces
kubectl delete meshes --all --all-namespaces

# Delete all existing App Mesh CRDs.
kubectl delete customresourcedefinition/virtualservices.appmesh.k8s.aws
kubectl delete customresourcedefinition/virtualnodes.appmesh.k8s.aws
kubectl delete customresourcedefinition/meshes.appmesh.k8s.aws
# Note: If CRDs are stuck in deletion, it means there still exists some App Mesh CRs, please check and delete them.
```

Run the `appmesh-controller/upgrade/pre_upgrade_check.sh` script and make sure it passes before you proceed

Translate the saved old YAML manifests using v1beta1 App Mesh CRD into v1beta2 App Mesh CRD format. Please refer to CRD types (
https://github.com/aws/aws-app-mesh-controller-for-k8s/tree/master/config/crd/bases) and Go types
(https://github.com/aws/aws-app-mesh-controller-for-k8s/tree/master/apis/appmesh/v1beta2) for the CRD Documentation.
Samples applications are in the repo https://github.com/aws/aws-app-mesh-examples for reference.

Note: Please specify the current appmesh resource names in the awsName field of the translated specs.

Install the appmesh-controller, label the namespace with values that mesh is selecting on and apply the translated manifest

### Upgrade from prior script installation

If you've installed the App Mesh controllers with scripts, you can remove the controllers with the steps below.
```sh
# remove injector objects
kubectl delete ns appmesh-inject
kubectl delete ClusterRoleBinding aws-app-mesh-inject-binding
kubectl delete ClusterRole aws-app-mesh-inject-cr
kubectl delete  MutatingWebhookConfiguration aws-app-mesh-inject

# remove controller objects
kubectl delete ns appmesh-system
kubectl delete ClusterRoleBinding app-mesh-controller-binding
kubectl delete ClusterRole app-mesh-controller
```
Run the `appmesh-controller/upgrade/pre_upgrade_check.sh` script and make sure it passes before you proceed

For handling the existing custom resources and the CRDs please refer to either of the previous upgrade sections as relevant.

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
$ helm delete appmesh-controller -n appmesh-system
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | ` 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/appmesh-controller`
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
`podLabels` | labels to add to each pod | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.create` | if `true`, create and use RBAC resources | `true`
`rbac.pspEnabled` | If `true`, create and use a restricted pod security policy | `false`
`serviceAccount.annotations` | optional annotations to add to service account | None
`serviceAccount.create` | If `true`, create a new service account | `true`
`serviceAccount.name` | Service account to be used | None
`sidecar.image.repository` | Envoy image repository | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy`
`sidecar.image.tag` | Envoy image tag | `<VERSION>`
`sidecar.logLevel` | Envoy log level | `info`
`sidecar.resources.requests` | Envoy container resource requests | `requests: cpu 10m memory 32Mi`
`sidecar.resources.limits` | Envoy container resource limits | `limits: cpu "" memory ""`
`sidecar.lifecycleHooks.preStopDelay` | Envoy container PreStop Hook Delay Value | `20s`
`sidecar.probes.readinessProbeInitialDelay` | Envoy container Readiness Probe Initial Delay | `1s`
`sidecar.probes.readinessProbePeriod` | Envoy container Readiness Probe Period | `10s`
`init.image.repository` | Route manager image repository | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-proxy-route-manager`
`init.image.tag` | Route manager image tag | `<VERSION>`
`stats.tagsEnabled` |  If `true`, Envoy should include app-mesh tags | `false`
`stats.statsdEnabled` |  If `true`, Envoy should publish stats to statsd endpoint @ 127.0.0.1:8125 | `false`
`cloudMapCustomHealthCheck.enabled` |  If `true`, CustomHealthCheck will be enabled for CloudMap Services | `false`
`cloudMapDNS.ttl` |  Sets CloudMap DNS TTL | `300`
`tracing.enabled` |  If `true`, Envoy will be configured with tracing | `false`
`tracing.provider` |  The tracing provider can be x-ray, jaeger or datadog | `x-ray`
`tracing.address` |  Jaeger or Datadog agent server address (ignored for X-Ray) | `appmesh-jaeger.appmesh-system`
`tracing.port` |  Jaeger or Datadog agent port (ignored for X-Ray) | `9411`
`enableCertManager` |  Enable Cert-Manager | `false`
`xray.image.repository` | X-Ray image repository | `amazon/aws-xray-daemon`
`xray.image.tag` | X-Ray image tag | `latest`
`accountId` | AWS Account ID for the Kubernetes cluster | None
`env` |  environment variables to be injected into the appmesh-controller pod | `{}`
