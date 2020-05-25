# AWS for fluent bit

A helm chart for [AWS-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)

# Installing the Chart

Add the EKS repository to Helm:

```
helm repo add eks https://aws.github.io/eks-charts
```

Install or upgrading the AWS for fluent bit chart with default configuration:

```
helm upgrade --install aws-for-fluent-bit --namespace kube-system eks/aws-for-fluent-bit
```

## Uninstalling the Chart

To uninstall/delete the `aws-for-fluent-bit` release:

```
helm delete aws-for-fluent-bit --namespace kube-system
```


## Configuration

| Parameter | Description | Default | Required |
| - | - | - | -
| `global.namespaceOverride` | Override the deployment namespace	| Not set (`Release.Namespace`) |
| `image.repository` | Image to deploy | `amazon/aws-for-fluent-bit` | ✔
| `image.tag` | Image tag to deploy | `2.2.0`
| `image.pullPolicy` | Pull policy for the image | `IfNotPresent` | ✔
| `serviceAccount.create` | Whether a new service account should be created | `true` | 
| `service.parsersFiles` | List of available parser files | `/fluent-bit/parsers/parsers.conf` |
| `service.extraParsers` | Adding more parsers with this value | `""` |
| `input.*` | Values for Kubernetes input | |
| `extraInputs` | Adding more inputs with this value | `""` |
| `filter.*` | Values for kubernetes filter | |
| `extraFilters` | Adding more filters with value | 
| `cloudWatch.enabled` | Whether this plugin should be enabled or not [details](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit) | `true` | ✔
| `cloudWatch.match` | The log filter | `*` | ✔
| `cloudWatch.region` | The AWS region for CloudWatch.  | `us-east-1` | ✔
| `cloudWatch.logGroupName` | The name of the CloudWatch Log Group that you want log records sent to. | `"/aws/eks/fluentbit-cloudwatch/logs"` | ✔
| `cloudWatch.logStreamName` | The name of the CloudWatch Log Stream that you want log records sent to. |  |
| `cloudWatch.logStreamPrefix` | Prefix for the Log Stream name. The tag is appended to the prefix to construct the full log stream name. Not compatible with the log_stream_name option. | `"fluentbit-"` |
| `cloudWatch.logKey` | By default, the whole log record will be sent to CloudWatch. If you specify a key name with this option, then only the value of that key will be sent to CloudWatch. For example, if you are using the Fluentd Docker log driver, you can specify logKey log and only the log message will be sent to CloudWatch. |  |
| `cloudWatch.logFormat` | An optional parameter that can be used to tell CloudWatch the format of the data. A value of json/emf enables CloudWatch to extract custom metrics embedded in a JSON payload. See the Embedded Metric Format. |  |
| `cloudWatch.roleArn` | ARN of an IAM role to assume (for cross account access). |  |
| `cloudWatch.autoCreateGroup` | Automatically create the log group. Valid values are "true" or "false" (case insensitive). | true |
| `cloudWatch.endpoint` | Specify a custom endpoint for the CloudWatch Logs API. |  |
| `cloudWatch.credentialsEndpoint` | Specify a custom HTTP endpoint to pull credentials from. [more info](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit) |  |
| `firehose.enabled` | Whether this plugin should be enabled or not, [details](https://github.com/aws/amazon-kinesis-firehose-for-fluent-bit) | `true` | ✔
| `firehose.match` | The log filter | `"*"` | ✔
| `firehose.region` | The region which your Firehose delivery stream(s) is/are in. | `"us-east-1"` | ✔
| `firehose.deliveryStream` | The name of the delivery stream that you want log records sent to. | `"my-stream"` | ✔
| `firehose.dataKeys` | By default, the whole log record will be sent to Kinesis. If you specify a key name(s) with this option, then only those keys and values will be sent to Kinesis. For example, if you are using the Fluentd Docker log driver, you can specify data_keys log and only the log message will be sent to Kinesis. If you specify multiple keys, they should be comma delimited. | |
| `firehose.roleArn` | ARN of an IAM role to assume (for cross account access). | |
| `firehose.endpoint` | Specify a custom endpoint for the Kinesis Firehose API. | |
| `firehose.timeKey` | Add the timestamp to the record under this key. By default the timestamp from Fluent Bit will not be added to records sent to Kinesis. | |
| `firehose.timeKeyFormat` | strftime compliant format string for the timestamp; for example, `%Y-%m-%dT%H:%M:%S%z`. This option is used with `time_key`. | |
| `kinesis.enabled` | Whether this plugin should be enabled or not, [details](https://github.com/aws/amazon-kinesis-streams-for-fluent-bit) | `true` | ✔
| `kinesis.match` | The log filter | `"*"` | ✔
| `kinesis.region` | The region which your Kinesis Data Stream is in. | `"us-east-1"` | ✔
| `kinesis.stream` | The name of the Kinesis Data Stream that you want log records sent to. | `"my-kinesis-stream-name"` | ✔
| `kinesis.partitionKey` | A partition key is used to group data by shard within a stream. A Kinesis Data Stream uses the partition key that is associated with each data record to determine which shard a given data record belongs to. For example, if your logs come from Docker containers, you can use container_id as the partition key, and the logs will be grouped and stored on different shards depending upon the id of the container they were generated from. As the data within a shard are coarsely ordered, you will get all your logs from one container in one shard roughly in order. If you don't set a partition key or put an invalid one, a random key will be generated, and the logs will be directed to random shards. If the partition key is invalid, the plugin will print an warning message. | `"container_id"` | ✔
| `kinesis.appendNewline` | If you set append_newline as true, a newline will be addded after each log record. | | 
| `kinesis.dataKeys` | By default, the whole log record will be sent to Kinesis. If you specify key name(s) with this option, then only those keys and values will be sent to Kinesis. For example, if you are using the Fluentd Docker log driver, you can specify data_keys log and only the log message will be sent to Kinesis. If you specify multiple keys, they should be comma delimited. | |
| `kinesis.roleArn` | ARN of an IAM role to assume (for cross account access). | |
| `kinesis.timeKey` | Add the timestamp to the record under this key. By default the timestamp from Fluent Bit will not be added to records sent to Kinesis. | |
| `kinesis.timeKeyFormat` |  strftime compliant format string for the timestamp; for example, `%Y-%m-%dT%H:%M:%S%z`. This option is used with `time_key`. | |
| `extraOutputs` | Adding more outputs with value | `""` |
| `priorityClassName` | Name of Priority Class to assign pods | `""` |
| `affinity` | A group of affinity scheduling rules for pod assignment | `{}` |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | List of node taints to tolerate | `{}` |
