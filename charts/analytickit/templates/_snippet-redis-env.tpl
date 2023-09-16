{{/* Common Redis ENV variables */}}
{{- define "snippet.redis-env" }}

- name: ANALYTICKIT_REDIS_HOST
  value: {{ include "analytickit.redis.host" . }}

- name: ANALYTICKIT_REDIS_PORT
  value: {{ include "analytickit.redis.port" . }}

{{- if (include "analytickit.redis.auth.enabled" .) }}
- name: ANALYTICKIT_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "analytickit.redis.secretName" . }}
      key: {{ include "analytickit.redis.secretPasswordKey" . }}
{{- end }}

{{- end }}
