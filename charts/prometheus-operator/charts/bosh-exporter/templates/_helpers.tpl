{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. This is suffixed with -alertmanager, which means subtract 13 from longest 63 available */}}
{{- define "bosh-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
The components in this chart create additional resources that expand the longest created name strings.
The longest name that gets created adds and extra 37 characters, so truncation should be 63-35=26.
*/}}
{{- define "bosh-exporter.fullname" -}}
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

{{/* Fullname suffixed with bosh-exporter */}}
{{- define "bosh-exporter.boshExporter.fullname" -}}
{{- printf "%s-bosh-exporter" (include "bosh-exporter.fullname" .) -}}
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "bosh-exporter.chartref" -}}
{{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end }}

{{/* Generate basic labels */}}
{{- define "bosh-exporter.labels" }}
chart: {{ template "bosh-exporter.chartref" . }}
release: {{ .Release.Name | quote }}
{{- end }}

{{/* Create the name of bosh exporter service account to use */}}
{{- define "bosh-exporter.boshExporter.serviceAccountName" -}}
{{- if .Values.boshExporter.serviceAccount.create -}}
    {{ default (include "bosh-exporter.boshExporter.fullname" .) .Values.boshExporter.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.boshExporter.serviceAccount.name }}
{{- end -}}
{{- end -}}