# App Mesh Prometheus

App Mesh Prometheus Helm chart for Kubernetes

## Prerequisites

* Kubernetes >= 1.13

## Installing the Chart

Add the EKS repository to Helm:

```sh
helm repo add eks https://aws.github.io/eks-charts
```

Install App Mesh Prometheus:

```sh
helm upgrade -i appmesh-prometheus eks/appmesh-prometheus \
--namespace appmesh-system
```

Optional: Persist your data  
If you do not persist your Prometheus data, then it will only exist as long as the Prometheus pod is running. For Prometheus persistent storage, you need to use PersistentVolumeClaim.  
As for the volume plugin, we use EBS CSI Driver as an example, but you can use other popular volume plugins like NFS, Ceph etc.  
In configuration, replace *your-appmesh-cluster* as your EKS appmesh cluster name and *your-aws-account* as your AWS account ID.

Enable EBS CSI Driver:  
- Initialize iam-oidc-provider
```
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=your-appmesh-cluster --approve
```
- Create IAM role
```
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster your-appmesh-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```
- Addon the EBS driver to running cluster.
```
eksctl create addon --name aws-ebs-csi-driver --cluster your-appmesh-cluster --service-account-role-arn arn:aws:iam::your-aws-account:role/AmazonEKS_EBS_CSI_DriverRole --force
```

More details: https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html  

- Create a [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
and use `--set persistentVolumeClaim.claimName=<PVC-CLAIM-NAME>`.

```
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

```
helm upgrade -i appmesh-prometheus eks/appmesh-prometheus \
--namespace appmesh-system \
--set retention=12h \
--set persistentVolumeClaim.claimName=prometheus
```

The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `appmesh-prometheus` deployment:

```console
helm delete appmesh-prometheus --namespace appmesh-system
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | image repository | `prom/prometheus`
`image.tag` | image tag | `<VERSION>`
`image.pullPolicy` | image pull policy | `IfNotPresent`
`resources.requests/cpu` | pod CPU request | `100m`
`resources.requests/memory` | pod memory request | `256Mi`
`resources.limits/cpu` | pod CPU limit | `2000m`
`resources.limits/memory` | pod memory limit | `2Gi`
`affinity` | node/pod affinities | None
`nodeSelector` | node labels for pod assignment | `{}`
`tolerations` | list of node taints to tolerate | `[]`
`rbac.create` | if `true`, create and use RBAC resources | `true`
`rbac.pspEnabled` | if `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | if `true`, create a new service account | `true`
`serviceAccount.name` | service account to be used | None
`retention` |  when to remove old data | `6h`
`scrapeInterval` |  interval between consecutive scrapes | `5s`
`persistentVolumeClaim.claimName` |  specify an existing volume claim to be used for Prometheus data | None
`remoteWrite.enabled` | if `true`, write prometheus metrics to an external location | `false`
`remoteWrite.url` | the url of the endpoint to send samples to | None
`remoteWrite.bearer_token` | bearer token | None


## Troubleshooting

If the Prometheus port does not open properly, first determine if the Pod is functioning properly. The following is an not ready example:
```
kubectl -n appmesh-system get deploy,po,svc
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/appmesh-controller   1/1     1            1           42m
deployment.apps/appmesh-prometheus   0/1     1            0           33m

NAME                                      READY   STATUS    RESTARTS   AGE
pod/appmesh-controller-6dcf8c7787-zgh7w   1/1     Running   0          42m
pod/appmesh-prometheus-6d6ffbb888-5644r   0/1     Pending   0          30m

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/appmesh-controller-webhook-service   ClusterIP   10.100.96.3     <none>        443/TCP    42m
service/appmesh-prometheus                   ClusterIP   10.100.53.248   <none>        9090/TCP   33m
```
If the Pod status is unhealthy and you use PVC for persistent storage, first check the status of the PVC, and check the log in event:  
```
kubectl describe pvc -n appmesh-system
```
If the problem is not solved, check the node's resource deployment, memory and CPU limits: 
```
kubectl describe nodes
```
If the node doesn't have enough resources, you can try [scaling the cluster](https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html).
