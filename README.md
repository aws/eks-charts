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
* [appmesh-spire-server](stable/appmesh-spire-server): App Mesh SPIRE Server Helm chart for Kubernetes
* [appmesh-spire-agent](stable/appmesh-spire-agent): App Mesh SPIRE Agent Helm chart for Kubernetes
* [appmesh-gateway](stable/appmesh-gateway): App Mesh Gateway Helm chart for Kubernetes
* [appmesh-inject](stable/appmesh-inject)(**deprecated**): App Mesh inject Helm chart for Kubernetes

### AWS Node Termination Handler
* [aws-node-termination-handler](stable/aws-node-termination-handler): Gracefully handle EC2 instance shutdown within Kubernetes. https://github.com/aws/aws-node-termination-handler

### AWS Calico
* [aws-calico](stable/aws-calico): Install Calico network policy enforcement on AWS

### AWS CloudWatch Metrics
* [aws-cloudwatch-metrics](stable/aws-cloudwatch-metrics): A helm chart for CloudWatch Agent to Collect Cluster Metrics

### AWS EBS CSI Driver
* [aws-ebs-csi-driver](stable/aws-ebs-csi-driver): A helm chart for Container Storage Interface (CSI) Driver which provides a CSI interface used by Container Orchestrators to manage the lifecycle of Amazon EBS volumes. https://github.com/kubernetes-sigs/aws-ebs-csi-driver

### AWS for Fluent Bit
* [aws-for-fluent-bit](stable/aws-for-fluent-bit): A helm chart for [AWS-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)

### AWS Load Balancer Controller
* [aws-load-balancer-controller](stable/aws-load-balancer-controller): A helm chart for [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)

### AWS VPC CNI
* [aws-vpc-cni](stable/aws-vpc-cni): Networking plugin for pod networking in Kubernetes using Elastic Network Interfaces on AWS. https://github.com/aws/amazon-vpc-cni-k8s

### AWS SIGv4 Proxy Admission Controller
* [aws-sigv4-proxy-admission-controller](stable/aws-sigv4-proxy-admission-controller): A helm chart for [AWS SIGv4 Proxy Admission Controller](https://github.com/aws-observability/aws-sigv4-proxy-admission-controller)

### AWS Secrets Manager and Config Provider for Secret Store CSI Driver
* [csi-secrets-store-provider-aws](stable/csi-secrets-store-provider-aws): A helm chart for [AWS Secrets Manager and Config Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws)

### Amazon EC2 Metadata Mock
* [amazon-ec2-metadata-mock](stable/amazon-ec2-metadata-mock): A tool to simulate Amazon EC2 instance metadata service for local testing


## License

This project is licensed under the Apache-2.0 License.
