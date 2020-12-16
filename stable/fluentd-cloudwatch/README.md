# Fluentd CloudWatch

Installs [Fluentd](https://www.fluentd.org/) [Cloudwatch](https://aws.amazon.com/cloudwatch/) log forwarder. This chart is derived from [incubator/fluentd-cloudwatch](https://github.com/helm/charts/tree/master/incubator/fluentd-cloudwatch) but modified to align with https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs.html.

## TL;DR;

```sh
helm repo add eks https://aws.github.io/eks-charts

helm install fluentd-cloudwatch eks/fluentd-cloudwatch
```

## Introduction

This chart bootstraps a [Fluentd](https://www.fluentd.org/) [Cloudwatch](https://aws.amazon.com/cloudwatch/) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `my-release`:

```sh
# use ec2 instance role credential
helm install my-release eks/fluentd-cloudwatch
# or add aws_access_key_id and aws_access_key_id with the key/password of a AWS user with a policy to access  Cloudwatch
helm install my-release eks/fluentd-cloudwatch --set awsAccessKeyId=aws_access_key_id_here --set awsSecretAccessKey=aws_secret_access_key_here
# or add a role to aws with the correct policy to add to cloud watch
helm install my-release eks/fluentd-cloudwatch --set awsRole=roll_name_here
```

The command deploys Fluentd Cloudwatch on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall the `my-release` deployment:

```sh
helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Fluentd Cloudwatch chart and their default values.

| Parameter                       | Description                                                                     | Default                               |
| ------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------|
| `image.repository`              | Image repository                                                                | `fluent/fluentd-kubernetes-daemonset` |
| `image.tag`                     | Image tag                                                                       | `v1.7.3-debian-cloudwatch-1.0`        |
| `image.pullPolicy`              | Image pull policy                                                               | `IfNotPresent`                        |
| `resources.limits.cpu`          | CPU limit                                                                       | `nil`                                 |
| `resources.limits.memory`       | Memory limit                                                                    | `400Mi`                               |
| `resources.requests.cpu`        | CPU request                                                                     | `100m`                                |
| `resources.requests.memory`     | Memory request                                                                  | `200Mi`                               |
| `podAnnotations`                | Annotations                                                                     | `{}`                                  |
| `podSecurityContext`            | Security Context                                                                | `{}`                                  |
| `awsRegion`                     | AWS Cloudwatch region                                                           | `us-east-1`                           |
| `clusterName`                   | The cloudwatch loggroup name will be derived using the cluster name             | `kubernetes`                          |
| `awsRole`                       | AWS IAM Role To Use                                                             | `nil`                                 |
| `awsAccessKeyId`                | AWS Access Key Id of a AWS user with a policy to access Cloudwatch              | `nil`                                 |
| `awsSecretAccessKey`            | AWS Secret Access Key of a AWS user with a policy to access Cloudwatch          | `nil`                                 |
| `config.conf`                   | Fluentd ConfigMap value. The main configuration is defined under `fluent.conf`  | `{}`                                  |
| `config.dataplane.enabled`      | Disable forwarding dataplane logs by setting this to `false`                    | `true`                                |
| `config.dataplane.conf`         | Customise dataplane log config. Defined under `systemd.conf`                    | `{}`                                  |
| `config.host.enabled`           | Disable forwarding host logs by setting this to `false`                         | `true`                                |
| `config.host.conf`              | Customise host log config. Defined under `host.conf`                            | `{}`                                  |
| `config.containers.enabled`     | Disable forwarding host logs by setting this to `false`                         | `true`                                |
| `config.containers.conf`        | Customise container log config. Defined under `containers.conf`                 | `{}`                                  |
| `rbac.create`                   | If true, create & use RBAC resources                                            | `true`                                |
| `rbac.serviceAccountName`       | existing ServiceAccount to use (ignored if rbac.create=true)                    | `default`                             |
| `rbac.serviceAccountAnnotations`| Additional Service Account annotations                                          | `{}`                                  |
| `rbac.pspEnabled`               | PodSecuritypolicy                                                               | `false`                               |
| `volumeMounts`                  | Add volume mounts to daemon set                                                 | `[]`                                  |
| `volumes`                       | Add volumes to daemon set                                                       | `[]`                                  |
| `tolerations`                   | Add tolerations                                                                 | `[]`                                  |
| `extraVars`                     | Add pod environment variables (must be specified as a single line object)       | `[]`                                  |
| `nodeSelector`                  | Node labels for pod assignment                                                  | `{}`                                  |
| `affinity`                      | Node affinity for pod assignment                                                | `{}`                                  |
| `priorityClassName`             | Set priority class for daemon set                                               | `nil`                                 |
| `busybox.repository`            | Image repository for the initcontainer                                          | `busybox`                             |
| `busybox.tag`                   | Image tag for the initcontainer                                                 | `1.31.0`                              |
