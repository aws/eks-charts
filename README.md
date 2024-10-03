# EKS Charts

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

### App Mesh

* [appmesh-controller](stable/appmesh-controller): App Mesh controller Helm chart for Kubernetes
* [appmesh-prometheus](stable/appmesh-prometheus): App Mesh Prometheus Helm chart for Kubernetes
* [appmesh-grafana](stable/appmesh-grafana): App Mesh Grafana Helm chart for Kubernetes
* [appmesh-jaeger](stable/appmesh-jaeger): App Mesh Jaeger Helm chart for Kubernetes
* [appmesh-spire-server](stable/appmesh-spire-server): App Mesh SPIRE Server Helm chart for Kubernetes
* [appmesh-spire-agent](stable/appmesh-spire-agent): App Mesh SPIRE Agent Helm chart for Kubernetes
* [appmesh-gateway](stable/appmesh-gateway): App Mesh Gateway Helm chart for Kubernetes
* [appmesh-inject](stable/appmesh-inject)(**deprecated**): App Mesh inject Helm chart for Kubernetes

### AWS Node Termination Handler

> [!WARNING]
> This Helm chart is now deprecated. Please see the current chart located in the [aws-node-termination-handler](https://github.com/aws/aws-node-termination-handler/tree/main/config/helm/aws-node-termination-handler) repository which is now published on [Public ECR](https://gallery.ecr.aws/aws-ec2/helm/aws-node-termination-handler)

### AWS CloudWatch Metrics

* [aws-cloudwatch-metrics](stable/aws-cloudwatch-metrics): A helm chart for CloudWatch Agent to Collect Cluster Metrics

### AWS for Fluent Bit

* [aws-for-fluent-bit](stable/aws-for-fluent-bit): A helm chart for [AWS-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)

### AWS Load Balancer Controller

> [!WARNING]
> This Helm chart is now deprecated. Please see the current chart located in the [aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller) repository which is now published on [Public ECR](https://gallery.ecr.aws/aws-ec2/helm/aws-node-termination-handler)

### AWS VPC CNI

* [aws-vpc-cni](stable/aws-vpc-cni): Networking plugin for pod networking in Kubernetes using Elastic Network Interfaces on AWS. <https://github.com/aws/amazon-vpc-cni-k8s>

### AWS SIGv4 Proxy Admission Controller

* [aws-sigv4-proxy-admission-controller](stable/aws-sigv4-proxy-admission-controller): A helm chart for [AWS SIGv4 Proxy Admission Controller](https://github.com/aws-observability/aws-sigv4-proxy-admission-controller)

### AWS Secrets Manager and Config Provider for Secret Store CSI Driver

> [!WARNING]
> This Helm chart is deprecated, please switch to [AWS Secrets Manager and Config Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) which is reviewed, owned and maintained by AWS

### Amazon EC2 Metadata Mock

* [amazon-ec2-metadata-mock](stable/amazon-ec2-metadata-mock): A tool to simulate Amazon EC2 instance metadata service for local testing

### CNI Metrics Helper

* [cni-metrics-helper](stable/cni-metrics-helper): A helm chart for [CNI Metrics Helper](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/cmd/cni-metrics-helper/README.md)

### EKS EFA K8s Device Plugin

* [aws-efa-k8s-device-plugin](stable/aws-efa-k8s-device-plugin): A helm chart for the [Elastic Fabric Adapter](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa.html) plugin, which automatically discovers and mounts EFA devices into pods that request them

## License

This project is licensed under the Apache-2.0 License.
