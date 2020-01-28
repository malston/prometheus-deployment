{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. This is suffixed with -alertmanager, which means subtract 13 from longest 63 available */}}
{{- define "pks-monitor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
The components in this chart create additional resources that expand the longest created name strings.
The longest name that gets created adds and extra 37 characters, so truncation should be 63-35=26.
*/}}
{{- define "pks-monitor.fullname" -}}
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

{{/* Fullname suffixed with pks-monitor */}}
{{- define "pks-monitor.pksMonitor.fullname" -}}
{{- printf "%s-pks-monitor" (include "pks-monitor.fullname" .) -}}
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "pks-monitor.chartref" -}}
{{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end }}

{{/* Generate basic labels */}}
{{- define "pks-monitor.labels" }}
chart: {{ template "pks-monitor.chartref" . }}
{{- end }}

{{/* Create the name of bosh exporter service account to use */}}
{{- define "pks-monitor.pksMonitor.serviceAccountName" -}}
{{- if .Values.pksMonitor.serviceAccount.create -}}
    {{ default (include "pks-monitor.pksMonitor.fullname" .) .Values.pksMonitor.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.pksMonitor.serviceAccount.name }}
{{- end -}}
{{- end -}}