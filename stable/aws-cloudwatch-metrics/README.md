# aws-cloudwatch-metrics

A helm chart for CloudWatch Agent to Collect Cluster Metrics

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install or upgrading aws-cloudwatch-metrics chart with default configuration:

```sh
helm upgrade --install aws-cloudwatch-metrics \
    --namespace amazon-cloudwatch eks/aws-cloudwatch-metric \
    --set clusterName=my-eks-cluster
```

## Using this chart with IRSA

1. Create IAM OIDC provider

```
eksctl utils associate-iam-oidc-provider \
  --region <aws-region> \
  --cluster <your-cluster-name> \
  --approve
```

2. Create a IAM role and ServiceAccount for the Cloudwatch Metrics agent

```
eksctl create iamserviceaccount \
  --cluster=<cluster-name> \
  --namespace=amazon-cloudwatch \
  --name=aws-cloudwatch-metrics \
  --attach-policy-arn=arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --approve
```

3. Install helm chart using Service Account

```
helm upgrade --install aws-cloudwatch-metrics \
  --namespace amazon-cloudwatch eks/aws-cloudwatch-metric \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-cloudwatch-metrics
```

## Configuration

| Parameter | Description | Default | Required |
| - | - | - | -
| `image.repository` | Image to deploy | `amazon/cloudwatch-agent` | ✔
| `image.tag` | Image tag to deploy | `1.247345.36b249270`
| `image.pullPolicy` | Pull policy for the image | `IfNotPresent` | ✔
| `clusterName` | Name of your cluster | `cluster_name` | ✔
| `serviceAccount.create` | Whether a new service account should be created | `true` | 
| `serviceAccount.name` | Service account to be used | | 
| `rbac.create` | Whether RBAC resources should be created | `true` | 
| `hostNetwork` | Allow to use the network namespace and network resources of the node | `false` | 
