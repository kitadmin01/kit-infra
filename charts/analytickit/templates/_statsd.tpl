{{/* Common statsd ENV variables and helpers used by AnalyticKit */}}

{{/* Return the statsd service host */}}
{{- define "analytickit.statsd.host" -}}
{{- if (index .Values "prometheus-statsd-exporter" "enabled") }}
  {{- printf "%s-prometheus-statsd-exporter" (include "analytickit.fullname" .) -}}
{{- else if .Values.externalStatsd.host }}
  {{- printf "%s" .Values.externalStatsd.host -}}
{{- end -}}
{{- end -}}

{{/* Return the statsd service port */}}
{{- define "analytickit.statsd.port" -}}
{{- if (index .Values "prometheus-statsd-exporter" "enabled") }}
  {{- index .Values "prometheus-statsd-exporter" "statsd" "tcpPort" }}
{{- else if .Values.externalStatsd.port }}
  {{- printf "%s" .Values.externalStatsd.port -}}
{{- end -}}
{{- end -}}

{{/* ENV used by AnalyticKit deployments for configuring statsd */}}
{{- define "snippet.statsd-env" }}
{{- if or (index .Values "prometheus-statsd-exporter" "enabled") (and (.Values.externalStatsd.host) (.Values.externalStatsd.port)) }}
- name: STATSD_HOST
  value: "{{ include "analytickit.statsd.host" . }}"
- name: STATSD_PORT
  value: "{{ include "analytickit.statsd.port" . }}"
{{- end }}
{{- end }}
