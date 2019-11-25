# AWS Node Termination Handler Chart
AWS Node Termination Handler Helm chart for Kubernetes. For more information on this project see the project repo at https://github.com/aws/aws-node-termination-handler. 
## Prerequisite
* Kubernetes >= 1.11
## Installing the Chart
Add the EKS repository to Helm:
```sh
helm repo add eks https://aws.github.io/eks-charts
```
Install AWS Node Termination Handler:
```sh
helm upgrade -i aws-node-termination-handler eks/aws-node-termination-handler
```
## Uninstalling the Chart

To uninstall/delete the `aws-node-termination-handler` deployment:

```console
helm delete --purge aws-node-termination-handler
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration
The following tables lists the configurable parameters of the chart and their default values.
| Parameter           | Description  | Default |
|---------------------|--------------|---------|
| `name`              | Main project keyword. All pods, cluster roles, service accounts, etc. are created under this name. | `"node-termination-handler"` |
| `namespace`         | The [kubernetes namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) | `"kube-system"` |
| `imageName`         | Refers to docker image located [here](https://hub.docker.com/r/amazon/aws-node-termination-handler). | `"amazon/aws-node-termination-handler"` |
| `imageVersion`      | Refers to current docker image version found [here](https://hub.docker.com/r/amazon/aws-node-termination-handler/tags). | `"v1.0.0"` |
| `deleteLocalData`   | Tells kubectl to continue even if there are pods using emptyDir (local data that will be deleted when the node is drained). | `"false"` |
| `ignoreDaemonsSets` | Causes kubectl to skip daemon set managed pods | `"true"` |
| `gracePeriod`       | The time in seconds given to each pod to terminate gracefully. If negative, the default value specified in the pod will be used. | `"30"` |
| `nodeSelector`      | Tells the daemon set where to place the node-termination-handler pods. For example, setting this to `lifecycle: "Ec2Spot"` would only place pods on nodes with that label. | `{}` |
