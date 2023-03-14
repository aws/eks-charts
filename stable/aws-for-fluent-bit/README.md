# AWS for fluent bit

A helm chart for [AWS-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit)

## Installing the Chart

Add the EKS repository to Helm:

```bash
helm repo add eks https://aws.github.io/eks-charts
```

Install or upgrading the AWS for fluent bit chart with default configuration:

```bash
helm upgrade --install aws-for-fluent-bit --namespace kube-system eks/aws-for-fluent-bit
```

## Uninstalling the Chart

To uninstall/delete the `aws-for-fluent-bit` release:

```bash
helm delete aws-for-fluent-bit --namespace kube-system
```

## Configuration

| Parameter | Description | Default | Required |
| - | - | - | -
| `global.namespaceOverride` | Override the deployment namespace | Not set (`Release.Namespace`) |
| `image.repository` | Image to deploy | `amazon/aws-for-fluent-bit` | ✔
| `image.tag` | Image tag to deploy | `2.28.4`
| `image.pullPolicy` | Pull policy for the image | `IfNotPresent` | ✔
| `rbac.pspEnabled` | Whether a pod security policy should be created | `false`
| `imagePullSecrets` | Docker registry pull secret | `[]` |
| `serviceAccount.create` | Whether a new service account should be created | `true` |
| `serviceAccount.name` | Name of the service account | `aws-for-fluent-bit` |
| `service.extraService` | Append to existing service with this value | `""` |
| `service.parsersFiles` | List of available parser files | `/fluent-bit/parsers/parsers.conf` |
| `service.extraParsers` | Adding more parsers with this value | `""` |
| `input.*` | Values for Kubernetes input | |
| `extraInputs` | Append to existing input with this value | `""` |
| `additionalInputs` | Adding more inputs with this value | `""` |
| `filter.*` | Values for kubernetes filter | |
| `filter.extraFilters` | Append to existing filter with value |
| `additionalFilters` | Adding more filters with value |
| `cloudWatch.enabled` | Enable this to activate old golang plugin [details](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit). For guidance on choosing go vs c plugin, please refer to [debugging guide](https://github.com/aws/aws-for-fluent-bit/blob/mainline/troubleshooting/debugging.md#aws-go-plugins-vs-aws-core-c-plugins) | `true` | ✔
| `cloudWatch.match` | The log filter | `*` | ✔
| `cloudWatch.region` | The AWS region for CloudWatch.  | `us-east-1` | ✔
| `cloudWatch.logGroupName` | The name of the CloudWatch Log Group that you want log records sent to. | `"/aws/eks/fluentbit-cloudwatch/logs"` | ✔
| `cloudWatch.logStreamName` | The name of the CloudWatch Log Stream that you want log records sent to. |  |
| `cloudWatch.logStreamPrefix` | Prefix for the Log Stream name. The tag is appended to the prefix to construct the full log stream name. Not compatible with the log_stream_name option. | `"fluentbit-"` |
| `cloudWatch.logKey` | By default, the whole log record will be sent to CloudWatch. If you specify a key name with this option, then only the value of that key will be sent to CloudWatch. For example, if you are using the Fluentd Docker log driver, you can specify logKey log and only the log message will be sent to CloudWatch. |  |
| `cloudWatch.logRetentionDays` | If set to a number greater than zero, and newly create log group's retention policy is set to this many days. | |
| `cloudWatch.logFormat` | An optional parameter that can be used to tell CloudWatch the format of the data. A value of json/emf enables CloudWatch to extract custom metrics embedded in a JSON payload. See the Embedded Metric Format. |  |
| `cloudWatch.roleArn` | ARN of an IAM role to assume (for cross account access). |  |
| `cloudWatch.autoCreateGroup` | Automatically create the log group. Valid values are "true" or "false" (case insensitive). | true |
| `cloudWatch.endpoint` | Specify a custom endpoint for the CloudWatch Logs API. |  |
| `cloudWatch.credentialsEndpoint` | Specify a custom HTTP endpoint to pull credentials from. [more info](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit) |  |
| `cloudWatch.extraOutputs` | Append extra outputs with value | `""` |
| `cloudWatchLogs.enabled` | This section is used to enable new high performance plugin. The Golang plugin was named `cloudwatch`; this new high performance CloudWatch plugin is called `cloudwatch_logs` in fluent bit configuration to prevent conflicts/confusion [details](https://docs.fluentbit.io/manual/pipeline/outputs/cloudwatch). For guidance on choosing go vs c plugin, please refer to [debugging guide](https://github.com/aws/aws-for-fluent-bit/blob/mainline/troubleshooting/debugging.md#aws-go-plugins-vs-aws-core-c-plugins) | `true` | ✔
| `cloudWatchLogs.match` | The log filter | `*` | ✔
| `cloudWatchLogs.region` | The AWS region for CloudWatch.  | `us-east-1` | ✔
| `cloudWatchLogs.logGroupName` | The name of the CloudWatch Log Group that you want log records sent to. | `"/aws/eks/fluentbit-cloudwatch/logs"` | ✔
| `cloudWatchLogs.logGroupTemplate` | Template for Log Group name using Fluent Bit [record_accessor](https://docs.fluentbit.io/manual/pipeline/outputs/cloudwatch#log-stream-and-group-name-templating-using-record_accessor-syntax) syntax. This field is optional and if configured it overrides the logGroupName. If the template translation fails, an error is logged and the logGroupName (which is still required) is used instead. |  |
| `cloudWatchLogs.logStreamName` | The name of the CloudWatch Log Stream that you want log records sent to. |  |
| `cloudWatchLogs.logStreamPrefix` | Prefix for the Log Stream name. The tag is appended to the prefix to construct the full log stream name. Not compatible with the log_stream_name option. | `"fluentbit-"` |
| `cloudWatchLogs.logStreamTemplate` | Template for Log Stream name using Fluent Bit [record_accessor](https://docs.fluentbit.io/manual/pipeline/outputs/cloudwatch#log-stream-and-group-name-templating-using-record_accessor-syntax) syntax. This field is optional and if configured it overrides the other log stream options. If the template translation fails, an error is logged and the log_stream_name or log_stream_prefix are used instead (and thus one of those fields is still required to be configured). |  |
| `cloudWatchLogs.logKey` | By default, the whole log record will be sent to CloudWatch. If you specify a key name with this option, then only the value of that key will be sent to CloudWatch. For example, if you are using the Fluentd Docker log driver, you can specify logKey log and only the log message will be sent to CloudWatch. Check the example [here](https://github.com/aws-samples/amazon-ecs-firelens-examples/tree/mainline/examples/fluent-bit/cloudwatchlogs#what-if-i-just-want-the-raw-log-line-from-the-container-to-appear-in-cloudwatch). |  |
| `cloudWatchLogs.logFormat` | An optional parameter that can be used to tell CloudWatch the format of the data. A value of json/emf enables CloudWatch to extract custom metrics embedded in a JSON payload. See the [Embedded Metric Format](https://github.com/aws-samples/amazon-ecs-firelens-examples/tree/mainline/examples/fluent-bit/cloudwatchlogs-emf). |  |
| `cloudWatchLogs.roleArn` | ARN of an IAM role to assume (for cross account access). |  |
| `cloudWatchLogs.autoCreateGroup` | Automatically create the log group. Valid values are "true" or "false" (case insensitive). | true |
| `cloudWatchLogs.logRetentionDays` | If set to a number greater than zero, and newly create log group's retention policy is set to this many days. | |
| `cloudWatchLogs.endpoint` | Specify a custom endpoint for the CloudWatch Logs API. |  |
| `cloudWatchLogs.metricNamespace` | An optional string representing the CloudWatch namespace for the metrics. Please refer to [tutorial](https://docs.fluentbit.io/manual/pipeline/outputs/cloudwatch#metrics-tutorial). |  |
| `cloudWatchLogs.metricDimensions` | A list of lists containing the dimension keys that will be applied to all metrics. If you have only one list of dimensions, put the values as a comma separated string. If you want to put list of lists, use the list as semicolon separated strings. Please refer to [tutorial](https://docs.fluentbit.io/manual/pipeline/outputs/cloudwatch#metrics-tutorial). |  |
| `cloudWatchLogs.stsEndpoint` | Specify a custom STS endpoint for the AWS STS API. |  |
| `cloudWatchLogs.autoRetryRequests` | Immediately retry failed requests to AWS services once. This option does not affect the normal Fluent Bit retry mechanism with backoff. Instead, it enables an immediate retry with no delay for networking errors, which may help improve throughput when there are transient/random networking issues. This option defaults to true. Please check [here]( https://github.com/aws/aws-for-fluent-bit/blob/mainline/troubleshooting/debugging.md#network-connection-issues) for more details |  |
| `cloudWatchLogs.externalId` | Specify an external ID for the STS API, can be used with the role_arn parameter if your role requires an external ID. |  |
| `cloudWatchLogs.extraOutputs` | Append extra outputs with value. This section helps you extend current chart implementation with ability to add extra parameters. For example, you can add [network](https://docs.fluentbit.io/manual/administration/networking) config like`cloudWatchLogs.extraOutputs.net.dns.mode=2`. | `""` |
| `firehose.enabled` | Whether this plugin should be enabled or not, [details](https://github.com/aws/amazon-kinesis-firehose-for-fluent-bit) | `true` | ✔
| `firehose.match` | The log filter | `"*"` | ✔
| `firehose.region` | The region which your Firehose delivery stream(s) is/are in. | `"us-east-1"` | ✔
| `firehose.deliveryStream` | The name of the delivery stream that you want log records sent to. | `"my-stream"` | ✔
| `firehose.dataKeys` | By default, the whole log record will be sent to Kinesis. If you specify a key name(s) with this option, then only those keys and values will be sent to Kinesis. For example, if you are using the Fluentd Docker log driver, you can specify data_keys log and only the log message will be sent to Kinesis. If you specify multiple keys, they should be comma delimited. | |
| `firehose.roleArn` | ARN of an IAM role to assume (for cross account access). | |
| `firehose.endpoint` | Specify a custom endpoint for the Kinesis Firehose API. | |
| `firehose.timeKey` | Add the timestamp to the record under this key. By default the timestamp from Fluent Bit will not be added to records sent to Kinesis. | |
| `firehose.timeKeyFormat` | strftime compliant format string for the timestamp; for example, `%Y-%m-%dT%H:%M:%S%z`. This option is used with `time_key`. | |
| `firehose.extraOutputs` | Append extra outputs with value | `""` |
| `kinesis.enabled` | Whether this plugin should be enabled or not, [details](https://github.com/aws/amazon-kinesis-streams-for-fluent-bit) | `true` | ✔
| `kinesis.match` | The log filter | `"*"` | ✔
| `kinesis.region` | The region which your Kinesis Data Stream is in. | `"us-east-1"` | ✔
| `kinesis.stream` | The name of the Kinesis Data Stream that you want log records sent to. | `"my-kinesis-stream-name"` | ✔
| `kinesis.partitionKey` | A partition key is used to group data by shard within a stream. A Kinesis Data Stream uses the partition key that is associated with each data record to determine which shard a given data record belongs to. For example, if your logs come from Docker containers, you can use container_id as the partition key, and the logs will be grouped and stored on different shards depending upon the id of the container they were generated from. As the data within a shard are coarsely ordered, you will get all your logs from one container in one shard roughly in order. If you don't set a partition key or put an invalid one, a random key will be generated, and the logs will be directed to random shards. If the partition key is invalid, the plugin will print an warning message. | `"container_id"` |
| `kinesis.appendNewline` | If you set append_newline as true, a newline will be addded after each log record. | |
| `kinesis.replaceDots` | Replace dot characters in key names with the value of this option. | |
| `kinesis.dataKeys` | By default, the whole log record will be sent to Kinesis. If you specify key name(s) with this option, then only those keys and values will be sent to Kinesis. For example, if you are using the Fluentd Docker log driver, you can specify data_keys log and only the log message will be sent to Kinesis. If you specify multiple keys, they should be comma delimited. | |
| `kinesis.roleArn` | ARN of an IAM role to assume (for cross account access). | |
| `kinesis.endpoint` | Specify a custom endpoint for the Kinesis Streams API. | |
| `kinesis.stsEndpoint` | Specify a custom endpoint for the STS API; used to assume your custom role provided with `kinesis.roleArn`. | |
| `kinesis.timeKey` | Add the timestamp to the record under this key. By default the timestamp from Fluent Bit will not be added to records sent to Kinesis. | |
| `kinesis.timeKeyFormat` |  strftime compliant format string for the timestamp; for example, `%Y-%m-%dT%H:%M:%S%z`. This option is used with `time_key`. | |
| `kinesis.aggregation` | Setting aggregation to `true` will enable KPL aggregation of records sent to Kinesis. This feature isn't compatible with the `partitionKey` feature.  See more about KPL aggregation [here](https://github.com/aws/amazon-kinesis-streams-for-fluent-bit#kpl-aggregation). | |
| `kinesis.compression` | Setting `compression` to `zlib` will enable zlib compression of each record. By default this feature is disabled and records are not compressed. | |
| `kinesis.extraOutputs` | Append extra outputs with value | `""` |
| `elasticsearch.enabled` | Whether this plugin should be enabled or not, [details](https://docs.fluentbit.io/manual/pipeline/outputs/elasticsearch) | `true` | ✔
| `elasticsearch.match` | The log filter | `"*"` | ✔
| `elasticsearch.awsRegion` | The region in which your Amazon OpenSearch Service cluster is in. | `"us-east-1"` | ✔
| `elasticsearch.host` | The url of the Elastic Search endpoint you want log records sent to. | | ✔
| `elasticsearch.awsAuth` | Enable AWS Sigv4 Authentication for Amazon ElasticSearch Service | On |
| `elasticsearch.tls` | Enable or disable TLS support | On |
| `elasticsearch.port` | TCP Port of the target service. | 443 |
| `elasticsearch.retryLimit` | Integer value to set the maximum number of retries allowed. N must be >= 1  | 6 |
| `elasticsearch.replaceDots` | Enable or disable Replace_Dots  | On |
| `elasticsearch.suppressTypeName` | OpenSearch 2.0 and above needs to have type option being removed by setting Suppress_Type_Name On  | |
| `elasticsearch.extraOutputs` | Append extra outputs with value | `""` |
| `s3.enabled` | Whether this plugin should be enabled or not, [details](https://docs.fluentbit.io/manual/pipeline/outputs/s3) | `true`
| `s3.match` | The log filter. | `"*"`
| `s3.bucket` | S3 Bucket name. |
| `s3.region` | The AWS region of your S3 bucket. | `"us-east-1"`
| `s3.jsonDateKey` | Specify the name of the time key in the output record. To disable the time key just set the value to false. | `"date"`
| `s3.jsonDateFormat` | Specify the format of the date. Supported formats are double, epoch, iso8601 (eg: 2018-05-30T09:39:52.000681Z) and java_sql_timestamp (eg: 2018-05-30 09:39:52.000681). | `"iso8601"`
| `s3.totalFileSize` | Specifies the size of files in S3. Maximum size is 50G, minimim is 1M. | `"100M"`
| `s3.uploadChunkSize` | The size of each 'part' for multipart uploads. Max: 50M | `"5M"`
| `s3.uploadTimeout` | Whenever this amount of time has elapsed, Fluent Bit will complete an upload and create a new file in S3. For example, set this value to 60m and you will get a new file every hour. | `"10m"`
| `s3.storeDir` | Directory to locally buffer data before sending. When multipart uploads are used, data will only be buffered until the `upload_chunk_size` is reached. S3 will also store metadata about in progress multipart uploads in this directory; this allows pending uploads to be completed even if Fluent Bit stops and restarts. It will also store the current $INDEX value if enabled in the S3 key format so that the $INDEX can keep incrementing from its previous value after Fluent Bit restarts. | `"/tmp/fluent-bit/s3"`
| `s3.storeDirLimitSize` | The size of the limitation for disk usage in S3. Limit the amount of s3 buffers in the `store_dir` to limit disk usage. Note: Use `store_dir_limit_size` instead of `storage.total_limit_size` which can be used to other plugins, because S3 has its own buffering system. | `0`
| `s3.s3KeyFormat` | Format string for keys in S3. This option supports a UUID, strftime time formatters, a syntax for selecting parts of the Fluent log tag using a syntax inspired by the rewrite_tag filter. Add $TAG in the format string to insert the full log tag; add $TAG[0] to insert the first part of the tag in the s3 key. | `"/pod-logs/$TAG/%Y-%m-%d/%H-%M-%S"`
| `s3.s3KeyFormatTagDelimiters` | A series of characters which will be used to split the tag into 'parts' for use with the s3_key_format option. See the in depth examples and tutorial in the [documentation](https://docs.fluentbit.io/manual/pipeline/outputs/s3/). |
| `s3.staticFilePath` | Disables behavior where UUID string is automatically appended to end of S3 key name when $UUID is not provided in s3_key_format. $UUID, time formatters, $TAG, and other dynamic key formatters all work as expected while this feature is set to true. | `false`
| `s3.usePutObject` | Use the S3 PutObject API, instead of the multipart upload API. When this option is on, key extension is only available when $UUID is specified in s3_key_format. | `false`
| `s3.roleArn` | ARN of an IAM role to assume (ex. for cross account access). |
| `s3.endpoint` | Custom endpoint for the S3 API. An endpoint can contain scheme and port. |
| `s3.stsEndpoint` | Custom endpoint for the STS API. |
| `s3.cannedAcl` | Predefined Canned ACL policy for S3 objects. |
| `s3.compression` | Compression type for S3 objects. 'gzip' is currently the only supported value by default. If Apache Arrow support was enabled at compile time, you can also use 'arrow'. |
| `s3.contentType` | A standard MIME type for the S3 object; this will be set as the Content-Type HTTP header. |
| `s3.sendContentMd5` | Send the Content-MD5 header with PutObject and UploadPart requests, as is required when Object Lock is enabled. | `false`
| `s3.autoRetryRequests` | Immediately retry failed requests to AWS services once. This option does not affect the normal Fluent Bit retry mechanism with backoff. Instead, it enables an immediate retry with no delay for networking errors, which may help improve throughput when there are transient/random networking issues. | `true`
| `s3.logKey` | By default, the whole log record will be sent to S3. If you specify a key name with this option, then only the value of that key will be sent to S3. For example, if you are using Docker, you can specify `log_key log` and only the log message will be sent to S3. |
| `s3.preserveDataOrdering` | Normally, when an upload request fails, there is a high chance for the last received chunk to be swapped with a later chunk, resulting in data shuffling. This feature prevents this shuffling by using a queue logic for uploads. | `true`
| `s3.storageClass` | Specify the storage class for S3 objects. If this option is not specified, objects will be stored with the default 'STANDARD' storage class. | |
| `s3.retryLimit`| Integer value to set the maximum number of retries allowed. Note: this configuration is released since version 1.9.10 and 2.0.1. For previous version, the number of retries is 5 and is not configurable. |`1`|
|`s3.externalId`| Specify an external ID for the STS API, can be used w ith the role_arn parameter if your role requires an external ID.
|`s3.extraOutputs`| Append extra outputs with value. This section helps you extend current chart implementation with ability to add extra parameters. For example, you can add [network](https://docs.fluentbit.io/manual/administration/networking) config like`s3.extraOutputs.net.dns.mode=2`. | |
|`opensearch.enabled`| Whether this plugin should be enabled or not, [details](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch) |`true`| ✔
|`opensearch.match`| The log filter |`"*"`| ✔
|`opensearch.host`| The url of the Opensearch Search endpoint you want log records sent to. | | ✔
|`opensearch.awsRegion`| The region in which your Opensearch search is/are in. |`"us-east-1"`|
|`opensearch.awsAuth`| Enable AWS Sigv4 Authentication for Amazon Opensearch Service. |`"On"`|
|`opensearch.tls`| Enable or disable TLS support | `"On"` |
|`opensearch.port`| TCP Port of the target service. |`443`|
|`opensearch.path`| OpenSearch accepts new data on HTTP query path "/_bulk". But it is also possible to serve OpenSearch behind a reverse proxy on a subpath. This option defines such path on the fluent-bit side. It simply adds a path prefix in the indexing HTTP POST URI. | |
|`opensearch.bufferSize`| Specify the buffer size used to read the response from the OpenSearch HTTP service. |`"5m"`|
|`opensearch.pipeline`| OpenSearch allows to setup filters called pipelines. This option allows to define which pipeline the database should use. For performance reasons is strongly suggested to do parsing and filtering on Fluent Bit side, avoid pipelines. | |
|`opensearch.awsStsEndpoint`| Specify the custom sts endpoint to be used with STS API for Amazon OpenSearch Service. | |
|`opensearch.awsRoleArn`| AWS IAM Role to assume to put records to your Amazon cluster. | |
|`opensearch.awsExternalId`| External ID for the AWS IAM Role specified with aws_role_arn. | |
|`opensearch.awsServiceName`| Service name to be used in AWS Sigv4 signature. For integration with Amazon OpenSearch Serverless, set to`aoss`. See the [FAQ](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch#faq) section on Amazon OpenSearch Serverless for more information. To use this option: make sure you set`image.tag`to`v2.30.0`or higher. | |
|`opensearch.httpUser`| Optional username credential for access. | |
|`opensearch.httpPasswd`| Password for user defined in HTTP_User. | |
|`opensearch.index`| Index name, supports [Record Accessor syntax](https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/classic-mode/record-accessor) |`"aws-fluent-bit"`|
|`opensearch.type`| Type name |`"_doc"`|
|`opensearch.logstashFormat`| Enable Logstash format compatibility. This option takes a boolean value: True/False, On/Off |`"on"`|
|`opensearch.logstashPrefix`| When Logstash_Format is enabled, the Index name is composed using a prefix and the date, e.g: If Logstash_Prefix is equals to 'mydata' your index will become 'mydata-YYYY.MM.DD'. The last string appended belongs to the date when the data is being generated. |`"logstash"`|
|`opensearch.logstashDateFormat`| Time format (based on strftime) to generate the second part of the Index name. |`"%Y.%m.%d"`|
|`opensearch.timeKey`| When Logstash_Format is enabled, each record will get a new timestamp field. The Time_Key property defines the name of that field. |`"@timestamp"`|
|`opensearch.timeKeyFormat`| When Logstash_Format is enabled, this property defines the format of the timestamp. |`"%Y-%m-%dT%H:%M:%S"`|
|`opensearch.timeKeyNanos`| When Logstash_Format is enabled, enabling this property sends nanosecond precision timestamps. |`"Off"`|
|`opensearch.includeTagKey`| When enabled, it append the Tag name to the record. |`"Off"`|
|`opensearch.tagKey`| When Include_Tag_Key is enabled, this property defines the key name for the tag. |`"_flb-key"`|
|`opensearch.generateId`| When enabled, generate _id for outgoing records. This prevents duplicate records when retrying. |`"Off"`|
|`opensearch.idKey`| If set, _id will be the value of the key from incoming record and Generate_ID option is ignored. | |
|`opensearch.writeOperation`| Operation to use to write in bulk requests. |`"create"`|
|`opensearch.replaceDots`| When enabled, replace field name dots with underscore. |`"Off"`|
|`opensearch.traceOutput`| When enabled print the OpenSearch API calls to stdout (for diag only) |`"Off"`|
|`opensearch.traceError`| When enabled print the OpenSearch API calls to stdout when OpenSearch returns an error (for diag only). |`"Off"`|
|`opensearch.currentTimeIndex`| Use current time for index generation instead of message record |`"Off"`|
|`opensearch.logstashPrefixKey`| When included: the value in the record that belongs to the key will be looked up and over-write the Logstash_Prefix for index generation. If the key/value is not found in the record then the Logstash_Prefix option will act as a fallback. Nested keys are not supported (if desired, you can use the nest filter plugin to remove nesting) | |
|`opensearch.suppressTypeName`| When enabled, mapping types is removed and Type option is ignored. |`"Off"`|
|`opensearch.extraOutputs`| Append extra outputs with value. This section helps you extend current chart implementation with ability to add extra parameters. For example, you can add [network](https://docs.fluentbit.io/manual/administration/networking) config like`opensearch.extraOutputs.net.dns.mode=2`. |`""`|
|`additionalOutputs`| add outputs with value |`""`|
|`priorityClassName`| Name of Priority Class to assign pods | |
|`updateStrategy`| Optional update strategy |`type: RollingUpdate`|
|`affinity`| Map of node/pod affinities |`{}`|
|`env`| Optional List of pod environment variables for the pods |`[]`|
|`tolerations`| Optional deployment tolerations |`[]`|
|`nodeSelector`| Node labels for pod assignment |`{}`|
|`annotations`| Optional pod annotations |`{}`|
|`volumes`| Volumes for the pods, provide as a list of volume objects (see values.yaml) |  volumes for /var/log and /var/lib/docker/containers are present, along with a fluentbit config volume |
|`volumeMounts`| Volume mounts for the pods, provided as a list of volumeMount objects (see values.yaml) | volumes for /var/log and /var/lib/docker/containers are mounted, along with a fluentbit config volume |
|`dnsPolicy`| Optional dnsPolicy |`ClusterFirst`|
|`hostNetwork`| If true, use hostNetwork |`false` |
