{{/*
Expand the name of the chart.
*/}}
{{- define "eks-pod-identity-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eks-pod-identity-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eks-pod-identity-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "eks-pod-identity-agent.labels" -}}
helm.sh/chart: {{ include "eks-pod-identity-agent.chart" . }}
{{ include "eks-pod-identity-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "eks-pod-identity-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "eks-pod-identity-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
The eks-pod-identity-agent image to use
*/}}
{{- define "eks-pod-identity-agent.image" -}}
{{- if .Values.image.override }}
{{- .Values.image.override }}
{{- else }}
{{- printf "%s/eks/eks-pod-identity-agent:%s" .Values.image.containerRegistry .Values.image.tag }}
{{- end }}
{{- end }}