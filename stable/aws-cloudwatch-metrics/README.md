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
    --namespace amazon-cloudwatch eks/aws-cloudwatch-metrics \
    --set clusterName=my-eks-cluster
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
| `hostNetwork` | Allow to use the network namespace and network resources of the node | `false` | 
