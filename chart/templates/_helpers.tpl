{{- define "keycloak.fullname" -}}
{{- printf "keycloak" }}
{{- end }}

{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
app.kubernetes.io/name: {{ include "keycloak.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
bnjns.uk/owner: backstage
backstage.uk/app: keycloak
{{ include "keycloak.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{- define "keycloak.selectorLabels" -}}
backstage.uk/component: keycloak
{{- end }}
