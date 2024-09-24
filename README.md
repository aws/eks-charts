![EKS Charts](https://github.com/aws/eks-charts/actions/workflows/ci.yaml/badge.svg)

## EKS Charts

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

### App Mesh

> [!WARNING]
> The following Helm charts are deprecated following the announcement of discontinued support for [AWS AppMesh](https://aws.amazon.com/blogs/containers/migrating-from-aws-app-mesh-to-amazon-ecs-service-connect/)

* `appmesh-controller`: App Mesh controller Helm chart for Kubernetes
* `appmesh-prometheus`: App Mesh Prometheus Helm chart for Kubernetes
* `appmesh-grafana`: App Mesh Grafana Helm chart for Kubernetes
* `appmesh-jaeger`: App Mesh Jaeger Helm chart for Kubernetes
* `appmesh-spire-server`: App Mesh SPIRE Server Helm chart for Kubernetes
* `appmesh-spire-agent`: App Mesh SPIRE Agent Helm chart for Kubernetes
* `appmesh-gateway`: App Mesh Gateway Helm chart for Kubernetes
* `appmesh-inject`: App Mesh inject Helm chart for Kubernetes

### AWS Node Termination Handler

* [aws-node-termination-handler](stable/aws-node-termination-handler): Gracefully handle EC2 instance shutdown within Kubernetes. <https://github.com/aws/aws-node-termination-handler>

### AWS Calico

> [!WARNING]
> This Helm chart is deprecated. To install Calico network policy enforcement on AWS, follow the EKS [user guide](https://docs.aws.amazon.com/eks/latest/userguide/calico.html).

### AWS CloudWatch Metrics

* [aws-cloudwatch-metrics](stable/aws-cloudwatch-metrics): A helm chart for CloudWatch Agent to Collect Cluster Metrics

### AWS for Fluent Bit

* [aws-for-fluent-bit](stable/aws-for-fluent-bit): A helm chart for [AWS-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)

### AWS Load Balancer Controller

* [aws-load-balancer-controller](stable/aws-load-balancer-controller): A helm chart for [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)

### AWS VPC CNI

* [aws-vpc-cni](stable/aws-vpc-cni): Networking plugin for pod networking in Kubernetes using Elastic Network Interfaces on AWS. <https://github.com/aws/amazon-vpc-cni-k8s>

### AWS SIGv4 Proxy Admission Controller

* [aws-sigv4-proxy-admission-controller](stable/aws-sigv4-proxy-admission-controller): A helm chart for [AWS SIGv4 Proxy Admission Controller](https://github.com/aws-observability/aws-sigv4-proxy-admission-controller)

### AWS Secrets Manager and Config Provider for Secret Store CSI Driver

**This Helm chart is deprecated, please switch to <https://aws.github.io/secrets-store-csi-driver-provider-aws/> which is reviewed, owned and maintained by AWS.**

* [csi-secrets-store-provider-aws](stable/csi-secrets-store-provider-aws): A helm chart for [AWS Secrets Manager and Config Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws)

### Amazon EC2 Metadata Mock

* [amazon-ec2-metadata-mock](stable/amazon-ec2-metadata-mock): A tool to simulate Amazon EC2 instance metadata service for local testing

### CNI Metrics Helper

* [cni-metrics-helper](stable/cni-metrics-helper): A helm chart for [CNI Metrics Helper](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/cmd/cni-metrics-helper/README.md)

### EKS EFA Plugin
* [aws-efa-k8s-device-plugin](stable/aws-efa-k8s-device-plugin): A helm chart for the [Elastic Fabric Adapter](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa.html) plugin, which automatically discovers and mounts EFA devices into pods that request them

## License

This project is licensed under the Apache-2.0 License.
