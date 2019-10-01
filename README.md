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

Install the App Mesh controller:

```sh
helm upgrade -i appmesh-controller eks/appmesh-controller --namespace appmesh-system
```

## License

This project is licensed under the Apache-2.0 License.

