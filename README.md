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
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/appmesh-controller/crds/crds.yaml
```

Install the App Mesh CRD controller:

```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
--namespace appmesh-system
```

Install the App Mesh admission controller:

```sh
helm upgrade -i appmesh-inject eks/appmesh-inject \
--namespace appmesh-system \
--set mesh.create=true \
--set mesh.name=global
```

If you've installed the App Mesh controllers with scripts, you can switch to Helm by
removing the controllers with:
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

**Note** that you shouldn't delete the App Mesh CRDs or the App Mesh custom resources
(virtual nodes or services) in your cluster.
Once you've removed the App Mesh controller and injector objects,
you can proceed with the Helm installation as described above.

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

#### AWS X-Ray 

Enable X-Ray tracing for the App Mesh data plane:

```sh
helm upgrade -i appmesh-inject eks/appmesh-inject \
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
helm upgrade -i appmesh-inject eks/appmesh-inject \
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
helm upgrade -i appmesh-inject eks/appmesh-inject \
--namespace appmesh-system \
--set tracing.enabled=true \
--set tracing.provider=datadog \
--set tracing.address=datadog.appmesh-system \
--set tracing.port=8126
```

**Note** that you should restart all pods running inside the mesh after enabling tracing.

## License

This project is licensed under the Apache-2.0 License.

