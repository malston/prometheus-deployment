{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. This is suffixed with -alertmanager, which means subtract 13 from longest 63 available */}}
{{- define "prometheus-deployment.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 50 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
The components in this chart create additional resources that expand the longest created name strings.
The longest name that gets created adds and extra 37 characters, so truncation should be 63-35=26.
*/}}
{{- define "prometheus-deployment.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 26 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 26 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 26 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Fullname suffixed with bosh-exporter */}}
{{- define "prometheus-deployment.boshExporter.fullname" -}}
{{- printf "%s-bosh-exporter" (include "prometheus-deployment.fullname" .) -}}
{{- end }}vl

{{/* Create chart name and version as used by the chart label. */}}
{{- define "prometheus-deployment.chartref" -}}
{{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end }}

{{/* Generate basic labels */}}
{{- define "prometheus-deployment.labels" }}
chart: {{ template "prometheus-deployment.chartref" . }}
# release: {{ $.Release.Name | quote }}
{{- end }}

{{/* Create the name of bosh exporter service account to use */}}
{{- define "prometheus-deployment.boshExporter.serviceAccountName" -}}
{{- if .Values.boshExporter.serviceAccount.create -}}
    {{ default (include "prometheus-deployment.boshExporter.fullname" .) .Values.boshExporter.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.boshExporter.serviceAccount.name }}
{{- end -}}
{{- end -}}