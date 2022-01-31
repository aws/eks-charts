{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "amazon-ec2-metadata-mock.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "amazon-ec2-metadata-mock.fullname" -}}
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
Equivalent to "amazon-ec2-metadata-mock.fullname" except that "-win" indicator is appended to the end.
Name will not exceed 63 characters.
*/}}
{{- define "amazon-ec2-metadata-mock.fullname.windows" -}}
{{- include "amazon-ec2-metadata-mock.fullname" . | trunc 59 | trimSuffix "-" | printf "%s-win" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "amazon-ec2-metadata-mock.labels" -}}
app.kubernetes.io/name: {{ include "amazon-ec2-metadata-mock.name" . }}
helm.sh/chart: {{ include "amazon-ec2-metadata-mock.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "amazon-ec2-metadata-mock.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "amazon-ec2-metadata-mock.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "amazon-ec2-metadata-mock.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get the default node selector term prefix.

In 1.14 "beta.kubernetes.io" was deprecated and is scheduled for removal in 1.18.
See https://v1-14.docs.kubernetes.io/docs/setup/release/notes/#deprecations
*/}}
{{- define "amazon-ec2-metadata-mock.defaultNodeSelectorTermsPrefix" -}}
    {{- $k8sVersion := printf "%s.%s" .Capabilities.KubeVersion.Major .Capabilities.KubeVersion.Minor | replace "+" "" -}}
    {{- semverCompare "<1.18" $k8sVersion | ternary "beta.kubernetes.io" "kubernetes.io" -}}
{{- end -}}

{{/*
Get the default node selector OS term.
*/}}
{{- define "amazon-ec2-metadata-mock.defaultNodeSelectorTermsOs" -}}
    {{- list (include "amazon-ec2-metadata-mock.defaultNodeSelectorTermsPrefix" .) "os" | join "/" -}}
{{- end -}}

{{/*
Get the default node selector Arch term.
*/}}
{{- define "amazon-ec2-metadata-mock.defaultNodeSelectorTermsArch" -}}
    {{- list (include "amazon-ec2-metadata-mock.defaultNodeSelectorTermsPrefix" .) "arch" | join "/" -}}
{{- end -}}

{{/*
Get the node selector OS term.
*/}}
{{- define "amazon-ec2-metadata-mock.nodeSelectorTermsOs" -}}
    {{- or .Values.nodeSelectorTermsOs (include "amazon-ec2-metadata-mock.defaultNodeSelectorTermsOs" .) -}}
{{- end -}}

{{/*
Get the node selector Arch term.
*/}}
{{- define "amazon-ec2-metadata-mock.nodeSelectorTermsArch" -}}
    {{- or .Values.nodeSelectorTermsArch (include "amazon-ec2-metadata-mock.defaultNodeSelectorTermsArch" .) -}}
{{- end -}}