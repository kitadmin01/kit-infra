{{/* Common AnalyticKit definitions */}}

{{- define "analytickit.analytickitSecretKey.existingSecret" }}
  {{- if .Values.analytickitSecretKey.existingSecret -}}
    {{- .Values.analytickitSecretKey.existingSecret -}}
  {{- else -}}
    {{- template "analytickit.fullname" . -}}
  {{- end -}}
{{- end }}

{{- define "snippet.analytickit-env" }}
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ template "analytickit.analytickitSecretKey.existingSecret" . }}
      key: {{ .Values.analytickitSecretKey.existingSecretKey }}
- name: SITE_URL
  value: {{ template "analytickit.site.url" . }}
- name: DEPLOYMENT
  value: {{ template "analytickit.deploymentEnv" . }}
- name: CAPTURE_INTERNAL_METRICS
  value: {{ .Values.web.internalMetrics.capture | quote }}
- name: HELM_INSTALL_INFO
  value: {{ template "analytickit.helmInstallInfo" . }}
- name: LOGGING_FORMATTER_NAME
  value: json
{{- end }}

{{- define "snippet.analytickit-sentry-env" }}
- name: SENTRY_DSN
  value: {{ .Values.sentryDSN | quote }}
{{- end }}
