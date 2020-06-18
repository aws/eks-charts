[![CircleCI](https://circleci.com/gh/aws/eks-charts.svg?style=svg)](https://circleci.com/gh/aws/eks-charts)

## EKS Charts

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

### App Mesh
* [appmesh-controller](stable/appmesh-controller): App Mesh controller Helm chart for Kubernetes
* [appmesh-prometheus](stable/appmesh-prometheus): App Mesh Prometheus Helm chart for Kubernetes
* [appmesh-grafana](stable/appmesh-grafana): App Mesh Grafana Helm chart for Kubernetes
* [appmesh-jaeger](stable/appmesh-jaeger): App Mesh Jaeger Helm chart for Kubernetes
* [appmesh-inject](stable/appmesh-inject)(**deprecated**): App Mesh inject Helm chart for Kubernetes

## License

This project is licensed under the Apache-2.0 License.