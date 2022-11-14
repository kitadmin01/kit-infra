{{/* Common pgbouncer helpers used by AnalyticKit */}}

{{/*
Set pgbouncer host
*/}}
{{- define "analytickit.pgbouncer.host" -}}
    {{- template "analytickit.fullname" . }}-pgbouncer
{{- end -}}

{{/*
Set pgbouncer port
*/}}
{{- define "analytickit.pgbouncer.port" -}}
    6543
{{- end -}}
