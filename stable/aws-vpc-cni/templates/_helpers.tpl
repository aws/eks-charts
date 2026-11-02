{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aws-vpc-cni.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aws-vpc-cni.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aws-vpc-cni.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aws-vpc-cni.labels" -}}
app.kubernetes.io/name: {{ include "aws-vpc-cni.name" . }}
helm.sh/chart: {{ include "aws-vpc-cni.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
k8s-app: aws-node
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aws-vpc-cni.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "aws-vpc-cni.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
ECR account for one image. The chart default 602401143452 is replaced when
that image's region has a dedicated EKS add-on registry. Any other account
is kept.
*/}}
{{- define "aws-vpc-cni.regionAccount" -}}
{{- $dedicated := dict
  "af-south-1" "877085696533"
  "ap-east-1" "800184023465"
  "ap-east-2" "533267051163"
  "ap-south-2" "900889452093"
  "ap-southeast-3" "296578399912"
  "ap-southeast-4" "491585149902"
  "ap-southeast-5" "151610086707"
  "ap-southeast-6" "333609536671"
  "ap-southeast-7" "121268973566"
  "ca-west-1" "761377655185"
  "cn-north-1" "918309763551"
  "cn-northwest-1" "961992271922"
  "eu-central-2" "900612956339"
  "eu-south-1" "590381155156"
  "eu-south-2" "455263428931"
  "eusc-de-east-1" "877088126301"
  "il-central-1" "066635153087"
  "me-central-1" "759879836304"
  "me-south-1" "558608220178"
  "mx-central-1" "730335286997"
  "us-gov-east-1" "151742754352"
  "us-gov-west-1" "013241004608"
-}}
{{- $account := .account | toString -}}
{{- if and (eq $account "602401143452") (hasKey $dedicated .region) -}}
{{- index $dedicated .region -}}
{{- else -}}
{{- $account -}}
{{- end -}}
{{- end -}}

{{/*
ECR domain for one image. The chart default amazonaws.com is replaced when
that image's region uses a different EKS add-on registry domain. Any other
configured domain is kept.
https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
*/}}
{{- define "aws-vpc-cni.regionDomain" -}}
{{- $domains := dict
  "cn-north-1" "amazonaws.com.cn"
  "cn-northwest-1" "amazonaws.com.cn"
  "eusc-de-east-1" "amazonaws.eu"
-}}
{{- if and (eq .domain "amazonaws.com") (hasKey $domains .region) -}}
{{- index $domains .region -}}
{{- else -}}
{{- .domain -}}
{{- end -}}
{{- end -}}

{{/*
The aws-vpc-cni-init image to use
*/}}
{{- define "aws-vpc-cni.initImage" -}}
{{- if .Values.init.image.override }}
{{- .Values.init.image.override }}
{{- else if .Values.init.image.overrideRepository }}
{{- printf "%s:%s" .Values.init.image.overrideRepository .Values.init.image.tag }}
{{- else }}
{{- $account := include "aws-vpc-cni.regionAccount" (dict "account" .Values.init.image.account "region" .Values.init.image.region) | trim -}}
{{- $domain := include "aws-vpc-cni.regionDomain" (dict "domain" .Values.init.image.domain "region" .Values.init.image.region) | trim -}}
{{- printf "%s.dkr.%s.%s.%s/amazon-k8s-cni-init:%s" $account .Values.init.image.endpoint .Values.init.image.region $domain .Values.init.image.tag }}
{{- end }}
{{- end }}

{{/*
The aws-vpc-cni image to use
*/}}
{{- define "aws-vpc-cni.image" -}}
{{- if .Values.image.override }}
{{- .Values.image.override }}
{{- else if .Values.image.overrideRepository }}
{{- printf "%s:%s" .Values.image.overrideRepository .Values.image.tag }}
{{- else }}
{{- $account := include "aws-vpc-cni.regionAccount" (dict "account" .Values.image.account "region" .Values.image.region) | trim -}}
{{- $domain := include "aws-vpc-cni.regionDomain" (dict "domain" .Values.image.domain "region" .Values.image.region) | trim -}}
{{- printf "%s.dkr.%s.%s.%s/amazon-k8s-cni:%s" $account .Values.image.endpoint .Values.image.region $domain .Values.image.tag }}
{{- end }}
{{- end }}

{{/*
The aws-network-policy-agent image to use
*/}}
{{- define "aws-vpc-cni.nodeAgentImage" -}}
{{- if .Values.nodeAgent.image.override }}
{{- .Values.nodeAgent.image.override }}
{{- else if .Values.nodeAgent.image.overrideRepository }}
{{- printf "%s:%s" .Values.nodeAgent.image.overrideRepository .Values.nodeAgent.image.tag }}
{{- else }}
{{- $account := include "aws-vpc-cni.regionAccount" (dict "account" .Values.nodeAgent.image.account "region" .Values.nodeAgent.image.region) | trim -}}
{{- $domain := include "aws-vpc-cni.regionDomain" (dict "domain" .Values.nodeAgent.image.domain "region" .Values.nodeAgent.image.region) | trim -}}
{{- printf "%s.dkr.%s.%s.%s/amazon/aws-network-policy-agent:%s" $account .Values.nodeAgent.image.endpoint .Values.nodeAgent.image.region $domain .Values.nodeAgent.image.tag }}
{{- end -}}
{{- end -}}

{{/*
The aws-network-policy-agent port to bind to for metrics
*/}}
{{- define "aws-vpc-cni.nodeAgentMetricsBindAddr" -}}
{{- printf ":%s" .Values.nodeAgent.metricsBindAddr }}
{{- end -}}

{{/*
The aws-network-policy-agent port to bind to for health probes
*/}}
{{- define "aws-vpc-cni.nodeAgentHealthProbeBindAddr" -}}
{{- printf ":%s" .Values.nodeAgent.healthProbeBindAddr }}
{{- end -}}
