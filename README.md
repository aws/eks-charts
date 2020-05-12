[![CircleCI](https://circleci.com/gh/aws/eks-charts.svg?style=svg)](https://circleci.com/gh/aws/eks-charts)

## EKS Charts

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

### App Mesh

Create the `appmesh-system` namespace:

```sh
kubectl create ns appmesh-system
```

Apply the App Mesh CRDs:

```sh
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/appmesh-manager/crds/crds.yaml
```

Install the App Mesh controller:

```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
--namespace appmesh-system
```

The new AppMesh controller v1.0.0 is backwards-incompatible with older AppMesh controllers(<v1.0.0) and v1beta1
AppMesh CRDs. If you have an old AppMesh controller/injector or v1beta1 AppMesh CRDs installed in your cluster, please
follow the steps in the relevant upgrade sections below

#### Upgrade without preserving old AppMesh resources

```sh
# Keep old AppMesh controller running, it is responsible to cleanup AppMesh resources in AWS
# Delete all existing AppMesh CRs
kubectl delete virtualservices --all --all-namespaces
kubectl delete virtualnodes --all --all-namespaces
kubectl delete meshes --all --all-namespaces

# Delete all existing AppMesh CRDs
kubectl delete customresourcedefinition/virtualservices.appmesh.k8s.aws
kubectl delete customresourcedefinition/virtualnodes.appmesh.k8s.aws
kubectl delete customresourcedefinition/meshes.appmesh.k8s.aws
# Note: If a CRD stuck in deletion, it means there still exists some AppMesh CRs, please check and delete them.

# Delete AppMesh controller
helm delete appmesh-controller -n appmesh-system

# Delete AppMesh injector
helm delete appmesh-inject -n appmesh-system
```
After cleanup, you can proceed with the installation steps described above

#### Upgrade preserving old AppMesh resources

```sh
# Save manifests of all existing AppMesh CRs:
kubectl get virtualservices --all-namespaces -o yaml > virtualservices.yaml
kubectl get virtualnodes --all-namespaces -o yaml > virtualnodes.yaml
kubectl get meshes --all-namespaces -o yaml > meshes.yaml

# Delete AppMesh controller, so it won’t clean up AppMesh resources in AWS while we deleting AppMesh CRs later.
helm delete appmesh-controller -n appmesh-system

# Delete AppMesh injector.
helm delete appmesh-inject -n appmesh-system

# Remove finalizers from all existing AppMesh CRs.  (Otherwise, you won’t be able to delete them)
# Delete all existing AppMesh CRs:
kubectl delete virtualservices --all --all-namespaces
kubectl delete virtualnodes --all --all-namespaces
kubectl delete meshes --all --all-namespaces

# Delete all existing AppMesh CRDs.
kubectl delete customresourcedefinition/virtualservices.appmesh.k8s.aws
kubectl delete customresourcedefinition/virtualnodes.appmesh.k8s.aws
kubectl delete customresourcedefinition/meshes.appmesh.k8s.aws
# Note: If CRDs are stuck in deletion, it means there still exists some AppMesh CRs, please check and delete them.
```
Translate the saved old YAML manifests using v1beta1 AppMesh CRD into v1beta2 AppMesh CRD format.
Install the appmesh-manager, and apply the translated manifest

#### Upgrade from prior script installation

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
For handling the custom resources and the CRDs please refer to either of the previous upgrade sections as relevant.

### App Mesh add-ons

#### Prometheus monitoring

Install App Mesh Prometheus:

```sh
helm upgrade -i appmesh-prometheus eks/appmesh-prometheus \
--namespace appmesh-system
```

Access Prometheus UI on `localhost:9090` with:

```sh
kubectl -n appmesh-system port-forward svc/appmesh-prometheus 9090:9090
```

To retain the monitoring data between chart upgrades or node restarts, you can create a 
[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims):

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus
  namespace: appmesh-system
  labels:
    app.kubernetes.io/name: appmesh-prometheus
spec:
  storageClassName: gp2
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
EOF
```

Install Prometheus with persistent storage:

```sh
helm upgrade -i appmesh-prometheus eks/appmesh-prometheus \
--namespace appmesh-system \
--set retention=12h \
--set persistentVolumeClaim.claimName=prometheus
```

#### Grafana

Install App Mesh Grafana:

```sh
helm upgrade -i appmesh-grafana eks/appmesh-grafana \
--namespace appmesh-system
```

Grafana uses Prometheus as data source and comes with dashboards for monitoring
the App Mesh control plane, Envoy data plane and [Flagger](https://flagger.app) canary releases.

Access Grafana on `localhost:3000` with:

```sh
kubectl -n appmesh-system port-forward svc/appmesh-grafana 3000:3000
```

#### AWS X-Ray 

Enable X-Ray tracing for the App Mesh data plane:

```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
--namespace appmesh-system \
--set tracing.enabled=true \
--set tracing.provider=x-ray
```

The above configuration will inject the AWS X-Ray daemon sidecar in each pod scheduled to run on the mesh.
**Note** that you should restart all pods running inside the mesh after enabling tracing.

#### Jaeger tracing

Install App Mesh Jaeger:

```sh
helm upgrade -i appmesh-jaeger eks/appmesh-jaeger \
--namespace appmesh-system
```

For Jaeger persistent storage you can create a [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
and use `--set persistentVolumeClaim.claimName=<PVC-CLAIM-NAME>`.

Access Jaeger UI on `localhost:16686` with:

```sh
kubectl -n appmesh-system port-forward svc/appmesh-jaeger 16686:16686
```

Enable Jaeger tracing for the App Mesh data plane:

```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
--namespace appmesh-system \
--set tracing.enabled=true \
--set tracing.provider=jaeger \
--set tracing.address=appmesh-jaeger.appmesh-system \
--set tracing.port=9411
```

**Note** that you should restart all pods running inside the mesh after enabling tracing.

#### Datadog tracing

Install the Datadog agent in the `appmesh-system` namespace and enable tracing for the App Mesh data plane:

```sh
helm upgrade -i appmesh-manager eks/appmesh-manager \
--namespace appmesh-system \
--set tracing.enabled=true \
--set tracing.provider=datadog \
--set tracing.address=datadog.appmesh-system \
--set tracing.port=8126
```

**Note** that you should restart all pods running inside the mesh after enabling tracing.

## License

This project is licensed under the Apache-2.0 License.

