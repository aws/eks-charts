# Amazon EC2 Metadata Mock

Amazon EC2 Metadata Mock(AEMM) Helm chart for Kubernetes. For more information on this project see the project repo at https://github.com/aws/amazon-ec2-metadata-mock.

## Prerequisites

* Kubernetes >= 1.14

## Installing the Chart

The helm chart can be installed from several sources. To install the chart with the release name amazon-ec2-metadata-mock and default configuration, pick a source below:

#### eks-charts
The chart for this project is hosted in [eks-charts](https://github.com/aws/eks-charts).

To get started you need to add the eks-charts repo to helm:

```
helm repo add eks https://aws.github.io/eks-charts
```

Then install with desired configs:

```
helm install amazon-ec2-metadata-mock \
  --namespace default
```

#### Local chart archive

Download and Install the chart archive from the latest release
```sh
curl -L https://github.com/aws/amazon-ec2-metadata-mock/releases/download/v1.10.0/amazon-ec2-metadata-mock-1.10.0.tgz
```

```sh
helm install amazon-ec2-metadata-mock amazon-ec2-metadata-mock-1.10.0.tgz \
  --namespace default
```

#### Unpacked local chart directory

Download the source code or unpack the archive from latest release and run
```sh
helm install amazon-ec2-metadata-mock ./helm/amazon-ec2-metadata-mock \
  --namespace default
```
----
To upgrade an already installed chart named amazon-ec2-metadata-mock:
```sh
helm upgrade amazon-ec2-metadata-mock ./helm/amazon-ec2-metadata-mock \
  --namespace default
```

### Installing the Chart with overridden values for AEMM configuration:

AEMM has an [extensive list of parameters](https://github.com/aws/amazon-ec2-metadata-mock#defaults) that can overridden. For simplicity, a selective list of parameters are configurable using Helm custom `values.yaml` or `--set argument`. To override parameters not listed in `values.yaml` use Kubernetes ConfigMap.

The [configuration](#configuration) section details the selective list of parameters. Alternatively, to retrieve the same information via helm, run:
```sh
helm show values ./helm/amazon-ec2-metadata-mock
```

* Passing a custom values.yaml to helm
```sh
helm install amazon-ec2-metadata-mock ./helm/amazon-ec2-metadata-mock \
  --namespace default -f path/to/myvalues.yaml 
```

* Passing custom values to Helm via CLI arguments
```sh
helm install amazon-ec2-metadata-mock ./helm/amazon-ec2-metadata-mock \
  --namespace default --set aemm.spot.action="stop",aemm.mockDelaySec=120
```

* Passing a config file to AEMM

 1. Create a Kubernetes ConfigMap from a custom AEMM configuration file:
See [Readme](https://github.com/aws/amazon-ec2-metadata-mock#configuration) to learn more about AEMM configuration. [Here](https://github.com/aws/amazon-ec2-metadata-mock/blob/main/test/e2e/testdata/output/aemm-config-used.json) is a reference config file to create your own `aemm-config.json`

    Note:
    * AEMM's native config `aemm.server.port` needs to be a fixed value (1338) to be able to run AEMM as a K8s service. So, overriding the `aemm.server.port` in the custom config file will work only when AEMM is accessed via the pod directly. To access the AEMM K8s service on a custom port, override `servicePort` (which is a Helm config).

    * The `configMapFileName` is used to mount the configMap on the containers running AEMM. The default file name is `aemm-config.json`. If a non-default file name was used to create the configMap, override `configMapFileName` in order for AEMM to be able to access it.

    ```sh
    kubectl create configmap aemm-config-map --from-file path/to/aemm-config.json
    ```

 2. Create `myvalues.yaml` with overridden value for configMap:
```yaml
configMap: "aemm-config-map"
servicePort: 1550
```

 3. Install AEMM with override:
```sh
helm install amazon-ec2-metadata-mock ./helm/amazon-ec2-metadata-mock \
  --namespace default -f path/to/myvalues.yaml 
```

## Making a HTTP request to the AEMM server running on a pod

1. Access AEMM pod / service
    i. Set up port-forwarding to access AEMM on your machine:

    ```sh
    kubectl get pods --namespace default
    ```

    ```sh
    kubectl port-forward pod/<AEMM-pod-name> 1338
    ```

    or

    ```
    kubectl port-forward service/amazon-ec2-metadata-mock-service 1338
    ```

    ii. Access AEMM from your application using the ClusterIP / DNS of the service or the pod directly.

2. Make the HTTP request

    ```sh
    # From outside the cluster:

    curl http://localhost:1338/latest/meta-data/spot/instance-action
    {
        "action": "terminate",
        "time": "2020-05-04T18:11:37Z"
    }
    ```
    or
    ```sh
    # From inside the cluster:
    # ClusterIP and port for the service should be available in the application pod's environment, if it was created after the AEMM service.

    curl http://$AMAZON_EC2_METADATA_MOCK_SERVICE_SERVICE_HOST:$AMAZON_EC2_METADATA_MOCK_SERVICE_SERVICE_PORT/latest/meta-data/spot/instance-action
    {
        "action": "terminate",
        "time": "2020-05-04T18:11:37Z"
    }
    ```
    or
    ```sh
    # From inside the cluster:

    curl http://amazon-ec2-metadata-mock-service.default.svc.cluster.local:1338/latest/meta-data/spot/instance-action
    {
        "action": "terminate",
        "time": "2020-05-04T18:11:37Z"
    }
    ```

## Uninstalling the Chart

To uninstall/delete the `amazon-ec2-metadata-mock` release:
```sh
helm uninstall amazon-ec2-metadata-mock
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

## Contributing to the Chart
While developing, use test/helm/chart-test.sh to test your changes. Preserve and reuse test environment, by using -p and -r options to run tests quickly.
```
/test/helm/chart-test.sh -h
```

Alternatively, the same tests can be run using:
```
make helm-lint-test # for linting only
make helm-e2e-test  # for e2e tests, including linting
```

### Versioning
Increment the chart version when one or more files in the helm chart directory changes:
* Increment patch version for readme changes
* Increment minor version for backward compatible changes / new minor version of the app (appVersion)
* Increment major version for incompatible changes / new major version of the app (appVersion)

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

### General
Parameter | Description | Default
--- | --- | --- 
`image.repository` | image repository | `public.ecr.aws/aws-ec2/amazon-ec2-metadata-mock`
`image.tag` | image tag | `<VERSION>` 
`image.pullPolicy` | image pull policy | `IfNotPresent`
`replicaCount` | defines the number of amazon-ec2-metadata-mock pods to replicate | `1`
`nameOverride` | override for the name of the Helm Chart (default, if not overridden: `amazon-ec2-metadata-mock`) | `""`
`fullnameOverride` | override for the name of the application (default, if not overridden: `amazon-ec2-metadata-mock`) | `""`
`targetNodeOs` | creates node-OS specific deployments (e.g. "linux", "windows", "linux windows") | `linux`
`nodeSelector` | tells both linux and windows deployments where to place the amazon-ec2-metadata-mock pods. | `{}`, meaning every node will receive a pod
`linuxNodeSelector` | tells the linux deployments where to place the amazon-ec2-metadata-mock pods. | `{}`, meaning every linux node will receive a pod
`windowsNodeSelector` | tells the windows deployments where to place the amazon-ec2-metadata-mock pods. | `{}`, meaning every windows node will receive a pod
`podAnnotations` | annotations to add to each pod | `{}`
`linuxAnnotations` | annotations to add to each linux pod | `{}`
`windowsAnnotations` | annotations to add to each windows pod | `{}`
`tolerations` | specifies taints that a pod tolerates so that it can be scheduled to a node with the same taint | `[]`
`linuxTolerations` | specifies taints that a linux pod tolerates so that it can be scheduled to a node with the same taint | `[]`
`windowsTolerations` | specifies taints that a windows pod tolerates so that it can be scheduled to a node with the same taint | `[]`
`updateStrategy` | the update strategy for a Deployment | `RollingUpdate`
`linuxUpdateStrategy` | the update strategy for a linux Deployment | `""`
`windowsUpdateStrategy` | the update strategy for a windows Deployment | `""`
`rbac.pspEnabled` | if `true`, create and use a restricted pod security policy | `false`
`serviceAccount.create` | if `true`, create a new service account | `true`
`serviceAccount.name` | service account to be used | `amazon-ec2-metadata-mock-service-account`
`serviceAccount.annotations` | specifies the annotations for service account | `{}`
`securityContext.runAsUserID` | user ID to run the container | `1000`
`securityContext.runAsGroupID` | group ID to run the container | `1000` 
`namespace` | Kubernetes namespace to use for AEMM pods | `default`
`configMap` | name of the Kubernetes ConfigMap to use to pass a config file for AEMM overrides | `""`
`configMapFileName` | name of the file used to create the Kubernetes ConfigMap | `aemm-config.json`
`servicePort` | port to run AEMM K8s Service on | `1338`
`serviceName` | name of the AEMM K8s Service | `amazon-ec2-metadata-mock-service`

### Helm chart tests
Parameter | Description | Default
--- | --- | ---
`test.image` | test image to use in the test pod |  `centos`
`test.imageTag` | test image tag |  `latest`
`test.pullPolicy` | test image pull policy |  `IfNotPresent`

### AEMM parameters
A selective list of AEMM parameters are configurable via Helm CLI and values.yaml file.
Use the [Kubernetes ConfigMap option](#installing-the-chart-with-overridden-values-for-aemm-configuration) to configure [other AEMM parameters](https://github.com/aws/amazon-ec2-metadata-mock/blob/main/test/e2e/testdata/output/aemm-config-used.json). 

Parameter | Description | Default in Helm | Default AEMM configuration
--- | --- | --- | ---
`aemm.server.hostname` | hostname to run AEMM on | `""`, in order to listen on all available interfaces e.g. ClusterIP | `0.0.0.0`
`aemm.mockDelaySec` | spot itn delay in seconds, relative to the start time of AEMM | `0` | `0`
`aemm.mockTriggerTime` | spot itn trigger time in RFC3339 format | `""` | `""`
`aemm.mockIPCount` | number of IPs that can receive spot interrupts and/or scheduled events; subsequent requests will return 404 | `""` | `2`
`aemm.imdsv2` | if true, IMDSv2 only works | `false` | `false`, meaning both IMDSv1/v2 work
`aemm.rebalanceDelaySec` | rebalance rec delay in seconds, relative to the start time of AEMM | `0` | `0`
`aemm.rebalanceTriggerTime` | rebalance rec trigger time in RFC3339 format | `""` | `""`
`aemm.spot.action` | action in the spot interruption notice | `""` | `terminate`
`aemm.spot.time` | time in the spot interruption notice | `""` | HTTP request time + 2 minutes
`aemm.spot.rebalanceRecTime` | time in the rebalance recommendation notification | `""` | HTTP request time
`aemm.events.code` | event code in the scheduled event | `""` | `system-reboot`
`aemm.events.notAfter` | the latest end time for the scheduled event | `""` | Start time of AEMM  + 7 days
`aemm.events.notBefore` | the earliest start time for the scheduled event | `""` | Start time of AEMM
`aemm.events.notBeforeDeadline` | the deadline for starting the event | `""` | Start time of AEMM  + 9 days
`aemm.events.state` | state of the scheduled event | `""` | `active`
