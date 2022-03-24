# App Mesh Controller

App Mesh controller Helm chart for Kubernetes

**Note**: If you wish to use [App Mesh preview](https://docs.aws.amazon.com/app-mesh/latest/userguide/preview.html) features, please refer to our [preview version](https://github.com/aws/eks-charts/blob/preview/stable/appmesh-controller/README.md) instructions.

## Prerequisites

* Kubernetes >= 1.14
* IAM permissions (see below)

## Installing the Chart

**Note**: AppMesh controller v1.0.0+ is **backwards incompatible** with old versions(e.g. v0.5.0).
If you're running an older version of App Mesh controller, please go to the [upgrade](#upgrade) section below before you proceed. If you are unsure, please run the `appmesh-controller/upgrade/pre_upgrade_check.sh` script to check if your cluster can be upgraded

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install the App Mesh CRDs:

```sh
kubectl apply -k "github.com/aws/eks-charts/stable/appmesh-controller//crds?ref=master"
```

Create namespace
```sh
kubectl create ns appmesh-system
```

The controller runs on the worker nodes, so it needs access to the AWS App Mesh / Cloud Map resources via IAM permissions. The IAM permissions can either be setup via IAM roles for service account or can be attached directly to the worker node IAM roles.

#### Setup IAM Role for Service Account

```
export CLUSTER_NAME=<eks-cluster-name>
export AWS_REGION=<aws-region e.g. us-east-1>
export AWS_ACCOUNT_ID=<AWS account ID>
```

Enable IAM OIDC provider
```sh
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION \
    --cluster=$CLUSTER_NAME \
    --approve
```

Download the IAM policy for AWS App Mesh Kubernetes Controller 
```
curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json
```

Create an IAM policy called AWSAppMeshK8sControllerIAMPolicy
```
aws iam create-policy \
    --policy-name AWSAppMeshK8sControllerIAMPolicy \
    --policy-document file://controller-iam-policy.json
```
Take note of the policy ARN that is returned

Create an IAM role for service account for the App Mesh Kubernetes controller, use the ARN from the step above

> Note: if you deleted `serviceaccount` in the `appmesh-system` namespace, you will need to delete and re-create `iamserviceaccount`. `eksctl` does not override the `iamserviceaccount` correctly ([see this issue](https://github.com/weaveworks/eksctl/issues/2665))

```
eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSAppMeshK8sControllerIAMPolicy  \
    --override-existing-serviceaccounts \
    --approve
```

Deploy appmesh-controller

**Note:** To enable mTLS via SDS(SPIRE), please set "sds.enabled=true".

```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

**Note**
Make sure that the Envoy proxies have the following IAM policies attached for the Envoy to authenticate with AWS App Mesh and fetch it's configuration
- https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/envoy-iam-policy.json

There are **2 ways** you can attach the above policy to the Envoy Pod  
#### With IRSA     
Download the Envoy IAM policy
```
curl -o envoy-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/envoy-iam-policy.json
```

Create an IAM policy called AWSAppMeshEnvoyIAMPolicy
```
aws iam create-policy \
    --policy-name AWSAppMeshEnvoyIAMPolicy \
    --policy-document file://envoy-iam-policy.json
```

Take note of the policy ARN that is returned

If your Mesh enabled applications are already using IRSA then you can attach the above policy to the role belonging to the existing IRSA or you can edit the Trust Relationship of the existing iam role which has this envoy policy so that some other service account in your mesh can also assume this role.  

If not then you can create a service account for your application namespace and use the ARN from the step above. Ensure that Application Namespace already exists

```
eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
    --namespace <ApplicationNamespaceName to which Envoy gets Injected> \
    --name envoy-proxy \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSAppMeshEnvoyIAMPolicy  \
    --override-existing-serviceaccounts \
    --approve
```

Reference this Service Account in your application pod spec. This should be the pod which would get injected with the Envoy. Refer below example:
```
https://github.com/aws/aws-app-mesh-examples/blob/5a2d04227593d292d52e5e2ca638d808ebed5e70/walkthroughs/howto-k8s-fargate/v1beta2/manifest.yaml.template#L220
``` 

#### Without IRSA  
Find the Node Instance IAM Role from your worker nodes and attach below policies to it.     
**Note** If you created service account for the controller as indicated above then you can skip attaching the Controller IAM policy to worker nodes. Instead attach only the Envoy IAM policy.

Controller IAM policy
- https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json
Use below command to download the policy if not already
```sh
curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json
```

Envoy IAM policy  
Attach the below envoy policy to your Worker Nodes (Node Instance IAM Role)
- https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/envoy-iam-policy.json  
Use below command to download the policy if not already
```sh
curl -o envoy-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/envoy-iam-policy.json
```

Apply the IAM policy directly to the worker nodes by replacing the `<NODE_INSTANCE_IAM_ROLE_NAME>`, `<policy-name>`, and `<policy-filename>` in below command:
```sh
aws iam put-role-policy --role-name <NODE_INSTANCE_IAM_ROLE_NAME> --policy-name <policy-name> --policy-document file://<policy-filename>
``` 

Deploy appmesh-controller
```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

### Installation on EKS with Fargate

```
export CLUSTER_NAME=<eks-cluster-name>
export AWS_REGION=<aws-region e.g. us-east-1>
export AWS_ACCOUNT_ID=<AWS account ID>
```

Create namespace
```sh
kubectl create ns appmesh-system
```

Setup EKS Fargate profile
```sh
eksctl create fargateprofile --cluster $CLUSTER_NAME --namespace appmesh-system
```

Enable IAM OIDC provider
```sh
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION --cluster=$CLUSTER_NAME --approve
```

Download the IAM policy for AWS App Mesh Kubernetes Controller
```
curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json
```

Create an IAM policy called AWSAppMeshK8sControllerIAMPolicy
```
aws iam create-policy \
    --policy-name AWSAppMeshK8sControllerIAMPolicy \
    --policy-document file://controller-iam-policy.json
```
Take note of the policy ARN that is returned

Create an IAM role for service account for the App Mesh Kubernetes controller, use the ARN from the step above

> Note: if you deleted `serviceaccount` in the `appmesh-system` namespace, you will need to delete and re-create `iamserviceaccount`. `eksctl` does not override the `iamserviceaccount` correctly ([see this issue](https://github.com/weaveworks/eksctl/issues/2665))

```
eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSAppMeshK8sControllerIAMPolicy  \
    --override-existing-serviceaccounts \
    --approve
```

Deploy appmesh-controller

**Note:** mTLS via SDS(SPIRE) is not supported on Fargate.

```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller
```

## Upgrade

This section will assist you in upgrading the appmesh-controller from <=v0.5.0 version to >=v1.0.0 version.

You can either build new CRDs from scratch or migrate existing CRDs to the new schema. Please refer to the documentation [here for the new API spec](https://aws.github.io/aws-app-mesh-controller-for-k8s/reference/api_spec/). Also, you can find several examples [here](https://github.com/aws/aws-app-mesh-examples/tree/master/walkthroughs) with v1beta2 spec to help you get started.

Starting v1.0.0, Mesh resource supports namespaceSelectors, where you can either select namespace based on labels (recommended option) or select all namespaces. To select a namespace in a Mesh, you will need to define `namespaceSelector`:

```
apiVersion: appmesh.k8s.aws/v1beta2
kind: Mesh
metadata:
  name: <mesh-name>
spec:
  namespaceSelector:
    matchLabels:
      mesh: <mesh-name> // any string value
```

Note: If you set `namespaceSelector: {}`, mesh will select all the namespace in your cluster. Labels on your namespace spec is a no-op when selecting all namespaces.

In the namespace spec, you will need to add a label `mesh: <mesh-name>`. Here's a sample namespace spec:

```
apiVersion: v1
kind: Namespace
metadata:
  name: ns
  labels:
    mesh: <mesh-name>
    appmesh.k8s.aws/sidecarInjectorWebhook: enabled
```

For more examples, please refer to the walkthroughs [here](https://github.com/aws/aws-app-mesh-examples/tree/master/walkthroughs). If you don't find an example that fits your use-case, please read the API spec [here](https://aws.github.io/aws-app-mesh-controller-for-k8s/reference/api_spec/). If you find an issue in the documentation or the examples, please open an issue and we'll help resolve it.

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
`sds.enabled` | If `true`, SDS will be enabled in Envoy | `false`
`sds.udsPath` | Unix Domain Socket Path of the SDS Provider(SPIRE in the current release) | `/run/spire/sockets/agent.sock`
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
`sidecar.image.repository` | Envoy image repository. If you override with non-Amazon built Envoy image, you will need to test/ensure it works with the App Mesh | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy`
`sidecar.image.tag` | Envoy image tag | `<VERSION>`
`sidecar.logLevel` | Envoy log level | `info`
`sidecar.envoyAdminAccessPort` | Envoy Admin Access Port | `9901`
`sidecar.envoyAdminAccessLogFile` | Envoy Admin Access Log File | `/tmp/envoy_admin_access.log`
`sidecar.resources.requests` | Envoy container resource requests | `requests: cpu 10m memory 32Mi`
`sidecar.resources.limits` | Envoy container resource limits | `limits: cpu "" memory ""`
`sidecar.lifecycleHooks.preStopDelay` | Envoy container PreStop Hook Delay Value | `20s`
`sidecar.probes.readinessProbeInitialDelay` | Envoy container Readiness Probe Initial Delay | `1s`
`sidecar.probes.readinessProbePeriod` | Envoy container Readiness Probe Period | `10s`
`init.image.repository` | Route manager image repository | `840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-proxy-route-manager`
`init.image.tag` | Route manager image tag | `<VERSION>`
`stats.tagsEnabled` |  If `true`, Envoy should include app-mesh tags | `false`
`stats.statsdEnabled` |  If `true`, Envoy should publish stats to statsd endpoint @ 127.0.0.1:8125 | `false`
`stats.statsdAddress` |  DogStatsD daemon IP address | `127.0.0.1`
`stats.statsdPort` |  DogStatsD daemon port | `8125`
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
`livenessProbe` | Liveness probe settings for the controller | (see `values.yaml`)
`podDisruptionBudget` | PodDisruptionBudget | `{}`