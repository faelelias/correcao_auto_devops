{{- define "ml-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ml-service.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "ml-service.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ml-service.labels" -}}
app.kubernetes.io/name: {{ include "ml-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "ml-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ml-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


