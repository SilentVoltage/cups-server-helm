{{/* vim: set filetype=mustache: */}}

{{- define "cups-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cups-server.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "cups-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cups-server.labels" -}}
helm.sh/chart: {{ include "cups-server.chart" . }}
{{ include "cups-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cups-server
{{- end -}}

{{- define "cups-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cups-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "cups-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "cups-server.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* Fully-qualified image reference, digest wins over tag */}}
{{- define "cups-server.image" -}}
{{- $reg := required "image.registry must be set" .Values.image.registry | trimSuffix "/" -}}
{{- $repo := required "image.repository must be set" .Values.image.repository -}}
{{- if .Values.image.digest -}}
{{- printf "%s/%s@%s" $reg $repo .Values.image.digest -}}
{{- else -}}
{{- printf "%s/%s:%s" $reg $repo (default .Chart.AppVersion .Values.image.tag) -}}
{{- end -}}
{{- end -}}

{{/* The exporter ships inside the main image unless explicitly overridden */}}
{{- define "cups-server.exporterImage" -}}
{{- $e := .Values.metrics.exporter.image -}}
{{- if and $e.repository $e.registry -}}
{{- printf "%s/%s:%s" (trimSuffix "/" $e.registry) $e.repository (default .Chart.AppVersion $e.tag) -}}
{{- else -}}
{{- include "cups-server.image" . -}}
{{- end -}}
{{- end -}}

{{- define "cups-server.pluginImage" -}}
{{- $p := .Values.plugins.image -}}
{{- printf "%s/%s:%s" (trimSuffix "/" $p.registry) $p.repository $p.tag -}}
{{- end -}}

{{/* Avahi runs from the main image unless explicitly overridden */}}
{{- define "cups-server.avahiImage" -}}
{{- $a := .Values.discovery.avahi.image -}}
{{- if and $a.repository $a.registry -}}
{{- printf "%s/%s:%s" (trimSuffix "/" $a.registry) $a.repository (default .Chart.AppVersion $a.tag) -}}
{{- else -}}
{{- include "cups-server.image" . -}}
{{- end -}}
{{- end -}}

{{/*
auth.mode interpretation, in one place so templates never re-derive it.

  enabled      -> a Secret with credentials is needed at all (ingress or cups)
  ingressAuth  -> emit Ingress basic-auth Secret + annotations
  cupsAuth     -> cupsd enforces its own Basic auth via PAM
*/}}
{{- define "cups-server.authEnabled" -}}
{{- if has .Values.auth.mode (list "ingress" "cups") -}}true{{- end -}}
{{- end -}}

{{- define "cups-server.ingressAuth" -}}
{{- if eq .Values.auth.mode "ingress" -}}true{{- end -}}
{{- end -}}

{{- define "cups-server.cupsAuth" -}}
{{- if eq .Values.auth.mode "cups" -}}true{{- end -}}
{{- end -}}

{{- define "cups-server.configSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-auth" (include "cups-server.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Comma-joined ingress hostnames.

Printed directly from `range` rather than accumulated into a variable: writing
to a variable declared outside a range is the one Go-template pattern that
silently yields nothing instead of erroring, so it stays out of this chart.
*/}}
{{- define "cups-server.ingressHostList" -}}
{{- range $i, $h := .Values.ingress.hosts -}}
{{- if $h.host -}}
{{- if $i }},{{ end }}{{ $h.host }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
external-dns annotations.
Usage: {{ include "cups-server.externalDNSAnnotations" (dict "ctx" . "kind" "ingress") }}
Hostnames fall back to the configured ingress hosts so a single toggle is enough.
*/}}
{{- define "cups-server.externalDNSAnnotations" -}}
{{- $ctx := .ctx -}}
{{- $kind := .kind -}}
{{- $ed := $ctx.Values.externalDNS -}}
{{- if $ed.enabled -}}
{{- if or (eq $ed.target "both") (eq $ed.target $kind) -}}
{{- $joined := $ed.hostnames | join "," | default (include "cups-server.ingressHostList" $ctx | trim) -}}
{{- if $joined }}
external-dns.alpha.kubernetes.io/hostname: {{ $joined | quote }}
{{- end }}
external-dns.alpha.kubernetes.io/ttl: {{ $ed.ttl | quote }}
{{- if $ed.aliasTarget }}
external-dns.alpha.kubernetes.io/target: {{ $ed.aliasTarget | quote }}
{{- end }}
{{- with $ed.extraAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Checksum of everything that lands in a mounted ConfigMap, so a config change
rolls the pod.

Derived from the *values* that drive those ConfigMaps rather than by rendering
them: `include $.Template.BasePath` only resolves templates that the current
render pass has loaded, which breaks under `helm unittest` (it loads just the
templates named by the suite) and under any partial render.
*/}}
{{- define "cups-server.configChecksum" -}}
{{- $parts := list
      (toYaml .Values.cups.extraConfig)
      (toYaml .Values.printers)
      (toYaml .Values.extraPPDs)
      (toYaml .Values.auth) -}}
{{- join "|" $parts | sha256sum -}}
{{- end -}}

{{- define "cups-server.pvcName" -}}
{{- $name := .name -}}
{{- $ctx := .ctx -}}
{{- printf "%s-%s" (include "cups-server.fullname" $ctx) $name -}}
{{- end -}}

{{/* Guardrails that must fail the render rather than produce a broken install */}}
{{- define "cups-server.validate" -}}
{{- if gt (int .Values.replicaCount) 1 -}}
{{- fail "cups-server: replicaCount > 1 is unsupported - cupsd is a singleton over an RWO spool volume" -}}
{{- end -}}
{{- if and .Values.ingress.enabled (not .Values.cups.serverAlias) -}}
{{- fail "cups-server: cups.serverAlias must be set when ingress.enabled=true (cupsd rejects unknown Host headers with HTTP 400)" -}}
{{- end -}}
{{- /* metrics guards live in servicemonitor.yaml / vmservicescrape.yaml */ -}}
{{- if and .Values.discovery.avahi.enabled (not .Values.hostNetwork) (not .Values.extraPodAnnotations) -}}
{{- /* warning only: multus users pass extraPodAnnotations */ -}}
{{- end -}}
{{- if not (has .Values.auth.mode (list "none" "ingress" "cups")) -}}
{{- fail (printf "cups-server: auth.mode must be one of none|ingress|cups, got %q" .Values.auth.mode) -}}
{{- end -}}
{{- /* auth.password may now be empty: the secret template auto-generates one
       and reuses it across upgrades, so an empty value is valid input rather
       than a misconfiguration. */ -}}
{{- end -}}
