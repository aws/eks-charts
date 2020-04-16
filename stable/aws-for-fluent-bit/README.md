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

| Parameter | Description | Default |
| - | - | - |
| `global.namespaceOverride` | Override the deployment namespace	| Not set (`Release.Namespace`) |
| `image.repository` | Image to deploy | `amazon/aws-for-fluent-bit` |
| `image.pullPolicy` | Pull policy for the image | `IfNotPresent` |
| `serviceAccount.create` | Whether a new service account should be created | `true`
| `service.parsersFiles` | List of available parser files | `/fluent-bit/parsers/parsers.conf` |
| `service.extraParserFile.enabled` | Create a new parser file with data | `true` |
| `service.extraParserFile.data` | Value for parser file config | `"logfmt parser"` |


## CloudWatch Plugin

[amazon-cloudwatch-logs-for-fluent-bit](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit)

| Parameter | Description | Default | Required 
| - | - | - | - 
| `enabled` | Whether this plugin should be enabled or not | `true` | ✔
| `match` | The log filter | `*` | ✔
| `region` | The AWS region for CloudWatch.  | `us-east-1` | ✔
| `logGroupName` | The name of the CloudWatch Log Group that you want log records sent to. | `"/aws/eks/fluentbit-cloudwatch/logs"` | ✔
| `logStreamName` | The name of the CloudWatch Log Stream that you want log records sent to. |  |
| `logStreamPrefix` | Prefix for the Log Stream name. The tag is appended to the prefix to construct the full log stream name. Not compatible with the log_stream_name option. | `"fluentbit-"` |
| `logKey` | By default, the whole log record will be sent to CloudWatch. If you specify a key name with this option, then only the value of that key will be sent to CloudWatch. For example, if you are using the Fluentd Docker log driver, you can specify logKey log and only the log message will be sent to CloudWatch. |  |
| `logFormat` | An optional parameter that can be used to tell CloudWatch the format of the data. A value of json/emf enables CloudWatch to extract custom metrics embedded in a JSON payload. See the Embedded Metric Format. |  |
| `roleArn` | ARN of an IAM role to assume (for cross account access). |  |
| `autoCreateGroup` | Automatically create the log group. Valid values are "true" or "false" (case insensitive). | true |
| `endpoint` | Specify a custom endpoint for the CloudWatch Logs API. |  |
| `credentialsEndpoint` | Specify a custom HTTP endpoint to pull credentials from. [more info](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit) |  |

## Firehose plugin

[amazon-kinesis-firehose-for-fluent-bit](https://github.com/aws/amazon-kinesis-firehose-for-fluent-bit)

| Parameter | Description | Default | Required 
| - | - | - | - 
| `enabled` | Whether this plugin should be enabled or not | `true` | ✔
| `match` | The log filter | `"*"` | ✔
| `region` | The region which your Firehose delivery stream(s) is/are in. | `"us-east-1"` | ✔
| `deliveryStream` | The name of the delivery stream that you want log records sent to. | `"my-stream"` | ✔
| `dataKeys` | By default, the whole log record will be sent to Kinesis. If you specify a key name(s) with this option, then only those keys and values will be sent to Kinesis. For example, if you are using the Fluentd Docker log driver, you can specify data_keys log and only the log message will be sent to Kinesis. If you specify multiple keys, they should be comma delimited. | |
| `roleArn` | ARN of an IAM role to assume (for cross account access). | |
| `endpoint` | Specify a custom endpoint for the Kinesis Firehose API. | |
| `timeKey` | Add the timestamp to the record under this key. By default the timestamp from Fluent Bit will not be added to records sent to Kinesis. | |
| `timeKeyFormat` | strftime compliant format string for the timestamp; for example, `%Y-%m-%dT%H:%M:%S%z`. This option is used with `time_key`. | |

## Kinesis plugin

[amazon-kinesis-streams-for-fluent-bit](https://github.com/aws/amazon-kinesis-streams-for-fluent-bit)

| Parameter | Description | Default | Required 
| - | - | - | - 
| `enabled` | Whether this plugin should be enabled or not | `true` | ✔
| `match` | The log filter | `"*"` | ✔
| `region` | The region which your Kinesis Data Stream is in. | `"us-east-1"` | ✔
| `stream` | The name of the Kinesis Data Stream that you want log records sent to. | `"my-kinesis-stream-name"` | ✔
| `partitionKey` | A partition key is used to group data by shard within a stream. A Kinesis Data Stream uses the partition key that is associated with each data record to determine which shard a given data record belongs to. For example, if your logs come from Docker containers, you can use container_id as the partition key, and the logs will be grouped and stored on different shards depending upon the id of the container they were generated from. As the data within a shard are coarsely ordered, you will get all your logs from one container in one shard roughly in order. If you don't set a partition key or put an invalid one, a random key will be generated, and the logs will be directed to random shards. If the partition key is invalid, the plugin will print an warning message. | `"container_id"` | ✔
| `appendNewline` | If you set append_newline as true, a newline will be addded after each log record. | | 
| `dataKeys` | By default, the whole log record will be sent to Kinesis. If you specify key name(s) with this option, then only those keys and values will be sent to Kinesis. For example, if you are using the Fluentd Docker log driver, you can specify data_keys log and only the log message will be sent to Kinesis. If you specify multiple keys, they should be comma delimited. | |
| `roleArn` | ARN of an IAM role to assume (for cross account access). | |
| `timeKey` | Add the timestamp to the record under this key. By default the timestamp from Fluent Bit will not be added to records sent to Kinesis. | |
| `timeKeyFormat` |  strftime compliant format string for the timestamp; for example, `%Y-%m-%dT%H:%M:%S%z`. This option is used with `time_key`. | |