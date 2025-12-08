{{- define "app-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app-service.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "app-service.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app-service.labels" -}}
app.kubernetes.io/name: {{ include "app-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "app-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


