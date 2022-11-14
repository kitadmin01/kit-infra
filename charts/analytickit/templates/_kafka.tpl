{{/* Common Kafka ENV variables and helpers used by AnalyticKit */}}

{{/* Return the Kafka fullname */}}
{{- define "analytickit.kafka.fullname" }}
{{- if .Values.kafka.fullnameOverride }}
{{- .Values.kafka.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .Values.kafka.nameOverride }}
{{- printf "%s-%s" .Release.Name .Values.kafka.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- printf "%s-%s" (include "analytickit.fullname" .) "kafka" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* Return the Kafka hosts (brokers) */}}
{{- define "analytickit.kafka.brokers"}}
{{- if .Values.kafka.enabled -}}
    {{- printf "%s:%d" (include "analytickit.kafka.fullname" .) (.Values.kafka.service.port | int) }}
{{- else -}}
    {{- printf "%s" .Values.externalKafka.brokers }}
{{- end }}
{{- end }}

{{/* ENV used by AnalyticKit deployments for connecting to Kafka */}}

{{- define "snippet.kafka-env" }}

{{- $hostsWithPrefix := list }}
{{- range $host := .Values.externalKafka.brokers }}
{{- $hostWithPrefix := (printf "kafka://%s" $host) }}
{{- $hostsWithPrefix = append $hostsWithPrefix $hostWithPrefix }}
{{- end }}
# Used by AnalyticKit/plugin-server. There is no specific reason for the difference. Expected format: comma-separated list of "host:port"
- name: KAFKA_HOSTS
{{- if .Values.kafka.enabled }}
  value: {{ ( include "analytickit.kafka.brokers" . ) }}
{{ else }}
  value: {{ join "," .Values.externalKafka.brokers | quote }}
{{- end }}
# Used by AnalyticKit/web. There is no specific reason for the difference. Expected format: comma-separated list of "kafka://host:port"
- name: KAFKA_URL
{{- if .Values.kafka.enabled }}
  value: {{ printf "kafka://%s" ( include "analytickit.kafka.brokers" . ) }}
{{ else }}
  value: {{ join "," $hostsWithPrefix | quote }}
{{- end }}
{{- end }}
