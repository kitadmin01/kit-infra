{{/* Common PostgreSQL ENV variables and helpers used by AnalyticKit */}}

{{/* ENV used by analytickit deployments for connecting to postgresql */}}
{{- define "snippet.postgresql-env" }}
- name: ANALYTICKIT_POSTGRES_HOST
  value: {{ template "analytickit.pgbouncer.host" . }}
- name: ANALYTICKIT_POSTGRES_PORT
  value: {{ include "analytickit.pgbouncer.port" . | quote }}
- name: ANALYTICKIT_DB_USER
  value: {{ include "analytickit.postgresql.username" . }}
- name: ANALYTICKIT_DB_NAME
  value: {{ include "analytickit.postgresql.database" . }}
- name: ANALYTICKIT_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "analytickit.postgresql.secretName" . }}
      key: {{ include "analytickit.postgresql.secretPasswordKey" . }}
- name: USING_PGBOUNCER
  value: 'true'
{{- end }}

{{/* ENV used by migrate job for connecting to postgresql */}}
{{- define "snippet.postgresql-migrate-env" }}
# Connect directly to postgres (without pgbouncer) to avoid statement_timeout for longer-running queries
- name: ANALYTICKIT_POSTGRES_HOST
  value: {{ template "analytickit.postgresql.host" . }}
- name: ANALYTICKIT_POSTGRES_PORT
  value: {{ include "analytickit.postgresql.port" . | quote }}
- name: ANALYTICKIT_DB_USER
  value: {{ include "analytickit.postgresql.username" . }}
- name: ANALYTICKIT_DB_NAME
  value: {{ include "analytickit.postgresql.database" . }}
- name: ANALYTICKIT_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "analytickit.postgresql.secretName" . }}
      key: {{ include "analytickit.postgresql.secretPasswordKey" . }}
- name: USING_PGBOUNCER
  value: 'false'
{{- end }}

{{/*
Create a default fully qualified postgresql app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "analytickit.postgresql.fullname" -}}
{{- if .Values.postgresql.fullnameOverride -}}
{{- .Values.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name .Values.postgresql.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "analytickit.fullname" .) "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres secret
*/}}
{{- define "analytickit.postgresql.secretName" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.existingSecret }}
{{- .Values.postgresql.existingSecret | quote -}}
{{- else if and (not .Values.postgresql.enabled) .Values.externalPostgresql.existingSecret }}
{{- .Values.externalPostgresql.existingSecret | quote -}}
{{- else -}}
{{- if .Values.postgresql.enabled -}}
{{- template "analytickit.postgresql.fullname" . -}}
{{- else -}}
{{- printf "%s-external" (include "analytickit.fullname" .) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres secret password key
*/}}
{{- define "analytickit.postgresql.secretPasswordKey" -}}
{{- if and (not .Values.postgresql.enabled) .Values.externalPostgresql.existingSecretPasswordKey }}
{{- .Values.externalPostgresql.existingSecretPasswordKey | quote -}}
{{- else -}}
"postgresql-password"
{{- end -}}
{{- end -}}

{{/*
Set postgres host
*/}}
{{- define "analytickit.postgresql.host" -}}
{{- if .Values.postgresql.enabled -}}
{{- template "analytickit.postgresql.fullname" . -}}
{{- else -}}
{{- required "externalPostgresql.postgresqlHost is required if not postgresql.enabled" .Values.externalPostgresql.postgresqlHost | quote }}
{{- end -}}
{{- end -}}

{{/*
Set postgres port
*/}}
{{- define "analytickit.postgresql.port" -}}
{{- if .Values.postgresql.enabled -}}
5432
{{- else -}}
{{- .Values.externalPostgresql.postgresqlPort -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres username
*/}}
{{- define "analytickit.postgresql.username" -}}
{{- if .Values.postgresql.enabled -}}
"postgres"
{{- else -}}
{{- .Values.externalPostgresql.postgresqlUsername | quote -}}
{{- end -}}
{{- end -}}

{{/*
Set postgres database
*/}}
{{- define "analytickit.postgresql.database" -}}
{{- if .Values.postgresql.enabled -}}
{{- .Values.postgresql.postgresqlDatabase | quote -}}
{{- else -}}
{{- .Values.externalPostgresql.postgresqlDatabase | quote -}}
{{- end -}}
{{- end -}}

{{/*
Set if postgres secret should be created
*/}}
{{- define "analytickit.postgresql.createSecret" -}}
{{- if and (not .Values.postgresql.enabled) .Values.externalPostgresql.postgresqlPassword -}}
{{- true -}}
{{- end -}}
{{- end -}}
