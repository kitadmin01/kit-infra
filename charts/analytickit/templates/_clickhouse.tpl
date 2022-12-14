{{/* Common ClickHouse ENV variables and helpers used by AnalyticKit */}}
{{- define "snippet.clickhouse-env" }}
{{- if .Values.clickhouse.enabled -}}
- name: CLICKHOUSE_HOST
  value: {{ template "analytickit.clickhouse.fullname" . }}
- name: CLICKHOUSE_CLUSTER
  value: {{ .Values.clickhouse.cluster | quote }}
- name: CLICKHOUSE_DATABASE
  value: {{ .Values.clickhouse.database | quote }}
- name: CLICKHOUSE_USER
  value: {{ .Values.clickhouse.user | quote }}
{{- if .Values.clickhouse.existingSecret }}
- name: CLICKHOUSE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.clickhouse.existingSecret }}
      key: {{ required "The existingSecretPasswordKey needs to be set when using an existingSecret" .Values.clickhouse.existingSecretPasswordKey }}
{{- else }}
- name: CLICKHOUSE_PASSWORD
  value: {{ .Values.clickhouse.password | quote }}
{{- end }}
- name: CLICKHOUSE_SECURE
  value: {{ .Values.clickhouse.secure | quote }}
- name: CLICKHOUSE_VERIFY
  value: {{ .Values.clickhouse.verify | quote }}
{{- else -}}
- name: CLICKHOUSE_HOST
  value: {{ required "externalClickhouse.host is required if not clickhouse.enabled" .Values.externalClickhouse.host | quote }}
- name: CLICKHOUSE_CLUSTER
  value: {{ required "externalClickhouse.cluster is required if not clickhouse.enabled" .Values.externalClickhouse.cluster | quote }}
- name: CLICKHOUSE_DATABASE
  value: {{ .Values.externalClickhouse.database | quote }}
- name: CLICKHOUSE_USER
  value: {{ required "externalClickhouse.user is required if not clickhouse.enabled" .Values.externalClickhouse.user | quote }}
{{- if .Values.externalClickhouse.existingSecret }}
- name: CLICKHOUSE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "analytickit.clickhouse.secretName" . }}
      key: {{ include "analytickit.clickhouse.secretPasswordKey" . }}
{{- else }}
- name: CLICKHOUSE_PASSWORD
  value: {{ required "externalClickhouse.password or externalClickhouse.existingSecret is required if using external clickhouse" .Values.externalClickhouse.password | quote }}
{{- end }}
- name: CLICKHOUSE_SECURE
  value: {{ .Values.externalClickhouse.secure | quote }}
- name: CLICKHOUSE_VERIFY
  value: {{ .Values.externalClickhouse.verify | quote }}
{{- end }}
{{- end }}


{*
   ------ CLICKHOUSE ------
*}

{{/*
Return clickhouse fullname
*/}}
{{- define "analytickit.clickhouse.fullname" -}}
{{- if .Values.clickhouse.fullnameOverride -}}
{{- .Values.clickhouse.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" "clickhouse" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Return true if a secret object for ClickHouse should be created
*/}}
{{- define "analytickit.clickhouse.createSecret" -}}
{{- if and (not .Values.clickhouse.enabled) (not .Values.externalClickhouse.existingSecret) .Values.externalClickhouse.password }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the ClickHouse secret name
*/}}
{{- define "analytickit.clickhouse.secretName" -}}
{{- if .Values.externalClickhouse.existingSecret }}
    {{- .Values.externalClickhouse.existingSecret | quote -}}
{{- else -}}
    {{- printf "%s-external" (include "analytickit.clickhouse.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the ClickHouse secret key
*/}}
{{- define "analytickit.clickhouse.secretPasswordKey" -}}
{{- if .Values.externalClickhouse.existingSecret }}
    {{- required "You need to provide existingSecretPasswordKey when an existingSecret is specified in externalClickhouse" .Values.externalClickhouse.existingSecretPasswordKey | quote }}
{{- else -}}
    {{- printf "clickhouse-password" -}}
{{- end -}}
{{- end -}}

{{/*
Return the ClickHouse image
*/}}
{{- define "analytickit.clickhouse.image" -}}
"{{ .Values.clickhouse.image.repository }}:{{ .Values.clickhouse.image.tag }}"
{{- end -}}

{{/*
Return the ClickHouse backup image
*/}}
{{- define "analytickit_backup.clickhouse.image" -}}
"{{ .Values.clickhouse.backup.image.repository }}:{{ .Values.clickhouse.backup.image.tag }}"
{{- end -}}

{{/*
Return the ClickHouse client image
*/}}
{{- define "client.clickhouse.image" -}}
"{{ .Values.clickhouse.client.image.repository }}:{{ .Values.clickhouse.client.image.tag }}"
{{- end -}}

{{/*
Return ClickHouse password config value for clickhouse_instance
*/}}
{{- define "clickhouse.passwordValue" -}}
{{- if .Values.clickhouse.existingSecret }}
      {{ .Values.clickhouse.user }}/k8s_secret_password: {{ .Values.clickhouse.existingSecret }}/{{ required "The existingSecretPasswordKey needs to be set when using an existingSecret" .Values.clickhouse.existingSecretPasswordKey }}
{{- else }}
      {{ .Values.clickhouse.user }}/password: {{ .Values.clickhouse.password }}
{{- end }}
{{- end }}

{{/*
Return ClickHouse backup password config value for clickhouse_instance
*/}}
{{- define "clickhouse.backupPasswordValue" -}}
{{- if .Values.clickhouse.backup.existingSecret }}
      {{ .Values.clickhouse.backup.backup_user }}/k8s_secret_password: {{ .Values.clickhouse.backup.existingSecret }}/{{ required "The backup.existingSecretPasswordKey needs to be set when using backup.existingSecret" .Values.clickhouse.backup.existingSecretPasswordKey }}
{{- else -}}
      {{ .Values.clickhouse.backup.backup_user }}/password: {{ .Values.clickhouse.backup.backup_password }}
{{- end}}
{{- end}}
