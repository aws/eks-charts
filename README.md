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
helm upgrade -i appmesh-controller eks/appmesh-controller --namespace appmesh-system
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

## License

This project is licensed under the Apache-2.0 License.

