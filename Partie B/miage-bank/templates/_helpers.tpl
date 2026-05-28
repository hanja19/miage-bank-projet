{{/*
Nom complet du chart
*/}}
{{- define "miage-bank.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels standards
*/}}
{{- define "miage-bank.labels" -}}
app: {{ .Release.Name }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
release: {{ .Release.Name }}
{{- end }}

{{/*
Nom du ServiceAccount dédié (Exigence TP)
*/}}
{{- define "miage-bank.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "miage-bank.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}