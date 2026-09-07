# cups-server

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.4.7](https://img.shields.io/badge/AppVersion-2.4.7-informational?style=flat-square)

Helm chart for an unprivileged CUPS print server on Kubernetes, with driver plugins, mDNS printer discovery and Prometheus metrics

**Homepage:** <https://github.com/silentvoltage/cups-server-helm>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| silentvoltage |  | <https://github.com/silentvoltage> |

## Source Code

* <https://github.com/silentvoltage/cups-server-helm>
* <https://github.com/silentvoltage/cups-server-docker>

## Requirements

Kubernetes: `>=1.25.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| auth.existingSecret | string | `""` | Supply credentials from a Secret you manage instead of the chart's.    Must contain the two keys named below. |
| auth.existingSecretPasswordKey | string | `"password"` |  |
| auth.existingSecretUserKey | string | `"username"` |  |
| auth.ingressController | string | `"traefik"` | Which ingress controller's basic-auth Secret format to emit. `traefik`    writes a `users` key (what the basicAuth Middleware reads); `nginx`    writes `auth`. Traefik's loader errors on a Secret containing more than    one candidate key, so this can't just emit both unconditionally. |
| auth.mode | string | `"none"` | How the CUPS admin interface is protected. One of:    none      No authentication anywhere. Anyone who can reach the pod can add,             modify and delete printers. Only sane on a trusted network with             networkPolicy.enabled=true.    ingress   Authentication happens at the Ingress (Traefik/nginx basic auth).             CUPS itself asks for nothing, so there is exactly one login             prompt. Requests that bypass the Ingress - anything hitting the             Service directly in-cluster - are NOT authenticated, so pair this             with networkPolicy.enabled=true.    cups      CUPS enforces its own Basic auth, in addition to any Ingress             auth. Uses pam_pwdfile (see the image's /etc/pam.d/cups) because             the stock PAM stack reads /etc/shadow, which this container             cannot write. Protects the Service path too, at the cost of two             login prompts when reached through an authenticated Ingress. |
| auth.password | string | `""` | Admin password. Leave empty to auto-generate a 24-char random one on first    install; it is stored in the `<release>-auth` Secret and reused on every    subsequent upgrade, so upgrades never rotate it.     Read it back with:      kubectl get secret <release>-auth -n <ns> \        -o jsonpath='{.data.password}' | base64 -d     The Secret is annotated `helm.sh/resource-policy: keep`, so `helm    uninstall` leaves it behind - an auto-generated password would otherwise    be unrecoverable. Delete the Secret by hand to force a new one. |
| auth.username | string | `"cupsadmin"` | Admin username. Used for both the Ingress basic-auth realm and CUPS. |
| cups.allowFrom | string | `"all"` | Comma/space separated allow rules for the `<Location />` blocks.    "all" is safe only when the NetworkPolicy below is enabled. |
| cups.browsing | string | `"off"` | cupsd's own CUPS-protocol browsing. Discovery is handled by cups-browsed. |
| cups.defaultShared | string | `"yes"` |  |
| cups.extraConfig | object | `{}` | Verbatim fragments appended to the rendered cupsd.conf (key -> content) |
| cups.logLevel | string | `"warn"` | cupsd log level: none|emerg|alert|crit|error|warn|notice|info|debug|debug2 |
| cups.maxJobTime | int | `10800` |  |
| cups.maxJobs | int | `500` |  |
| cups.preserveJobFiles | string | `"no"` |  |
| cups.preserveJobHistory | string | `"yes"` |  |
| cups.serverAlias | string | `"*"` | Host header whitelist. Required for Ingress access; cupsd returns HTTP 400    for unknown Host values. "*" accepts anything the Ingress forwards. |
| cups.serverName | string | `""` |  |
| cups.webInterface | string | `"yes"` |  |
| discovery.avahi | object | `{"allowInterfaces":"","command":["/usr/bin/tini","-g","--","/usr/local/bin/avahi-entrypoint.sh"],"config":"","denyInterfaces":"","enabled":true,"image":{"pullPolicy":"IfNotPresent","registry":"","repository":"","tag":""},"publish":false,"resources":{"limits":{"memory":"128Mi"},"requests":{"cpu":"10m","memory":"32Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"add":["SETUID","SETGID","SETPCAP","CHOWN","FOWNER"],"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsGroup":0,"runAsNonRoot":false,"runAsUser":0}}` | Avahi sidecar providing the mDNS stack that cups-browsed queries.  Defaults to the chart's own image, which runs dbus-daemon + avahi-daemon with dbus enabled. Third-party avahi images are frequently built with `enable-dbus=no`: avahi starts, cups-browsed connects to nothing, and no printers are discovered - with no error in either log. Override image.repository only if you know the image exposes the system bus. |
| discovery.avahi.allowInterfaces | string | `""` | Restrict Avahi to specific interfaces (comma separated). Useful with hostNetwork so it does not answer on the node's other NICs. |
| discovery.avahi.command | list | `["/usr/bin/tini","-g","--","/usr/local/bin/avahi-entrypoint.sh"]` | Entrypoint. Clear this ([]) when supplying a third-party avahi image. |
| discovery.avahi.config | string | `""` | Full avahi-daemon.conf override. Leave empty to use the generated one. |
| discovery.avahi.publish | bool | `false` | Publish this host's own services over mDNS. Off by default: the point of the sidecar is discovering printers, not advertising CUPS. |
| discovery.avahi.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"add":["SETUID","SETGID","SETPCAP","CHOWN","FOWNER"],"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsGroup":0,"runAsNonRoot":false,"runAsUser":0}` | Avahi needs uid 0 to start the system bus and to bind its runtime dirs; it drops to the avahi/messagebus users itself. This is why the container does not inherit the pod-level non-root context. |
| discovery.browseAllow | list | `[]` | CIDRs cups-browsed will accept advertisements from |
| discovery.browseDeny | list | `[]` |  |
| discovery.browseInterval | int | `60` |  |
| discovery.browsePoll | list | `[]` | Poll these CUPS servers directly (unicast fallback when mDNS is unroutable) |
| discovery.browseRemoteProtocols | string | `"dnssd cups"` |  |
| discovery.browseTimeout | int | `300` |  |
| discovery.createIPPPrinterQueues | string | `"All"` |  |
| discovery.enabled | bool | `true` | cups-browsed sidecar: creates local queues for printers found via DNS-SD |
| discovery.ippPrinterQueueType | string | `"Auto"` |  |
| discovery.localQueueNaming | string | `"DNSSD"` |  |
| discovery.resources.limits.memory | string | `"256Mi"` |  |
| discovery.resources.requests.cpu | string | `"25m"` |  |
| discovery.resources.requests.memory | string | `"64Mi"` |  |
| dnsPolicy | string | `""` |  |
| externalDNS.aliasTarget | string | `""` | Overrides the record target (CNAME) instead of resolving from the object |
| externalDNS.enabled | bool | `false` | Emit external-dns annotations on the Ingress and/or Service |
| externalDNS.extraAnnotations | object | `{}` | Extra external-dns annotations merged verbatim |
| externalDNS.hostnames | list | `[]` | Hostnames. Defaults to the ingress hosts when empty. |
| externalDNS.target | string | `"ingress"` | Target of the annotations: ingress | service | both |
| externalDNS.ttl | int | `300` |  |
| extraContainers | list | `[]` |  |
| extraEnv | list | `[]` |  |
| extraEnvFrom | list | `[]` |  |
| extraInitContainers | list | `[]` |  |
| extraObjects | list | `[]` |  |
| extraPPDs | object | `{}` | Extra PPD files rendered into a ConfigMap and mounted at /etc/cups/ppd |
| extraPodAnnotations | object | `{}` | Extra network attachment annotations, e.g. Multus macvlan |
| extraVolumeMounts | list | `[]` |  |
| extraVolumes | list | `[]` |  |
| fullnameOverride | string | `""` | Fully override the generated release name |
| hostNetwork | bool | `false` | mDNS/DNS-SD only works on the pod's L2 segment. Standard CNIs do not forward    multicast, so LAN printer discovery requires one of:      hostNetwork: true                    (simplest, pins the pod to a node)      a macvlan/ipvlan attachment via Multus (cleaner, needs Multus installed)      discovery.browsePoll against a reachable CUPS/IPP host (no multicast) |
| image.digest | string | `""` | Image digest (`sha256:...`). Takes precedence over `tag` when set. |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"ghcr.io"` | Image registry. Swap to docker.io for the Docker Hub mirror |
| image.repository | string | `"silentvoltage/cups-server"` | Image repository (without registry) |
| image.tag | string | `""` | Image tag. Defaults to `.Chart.AppVersion`. Prefer pinning a digest below. |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-body-size" | string | `"0"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-read-timeout" | string | `"600"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-send-timeout" | string | `"600"` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"cups.example.com"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| ingress.labels | object | `{}` |  |
| ingress.tls | list | `[]` |  |
| livenessProbe.enabled | bool | `true` |  |
| livenessProbe.failureThreshold | int | `5` |  |
| livenessProbe.initialDelaySeconds | int | `20` |  |
| livenessProbe.periodSeconds | int | `20` |  |
| livenessProbe.timeoutSeconds | int | `5` |  |
| metrics.enabled | bool | `true` |  |
| metrics.exporter.image | object | `{"registry":"","repository":"","tag":""}` | Defaults to the main image (the exporter ships inside it) |
| metrics.exporter.jobLimit | int | `1000` |  |
| metrics.exporter.logLevel | string | `"INFO"` |  |
| metrics.exporter.pageLog.enabled | bool | `true` | Parse /var/log/cups/page_log for cumulative page counters |
| metrics.exporter.pageLog.perUser | bool | `false` | Adds a `user` label. Watch cardinality on shared queues. |
| metrics.exporter.resources.limits.memory | string | `"128Mi"` |  |
| metrics.exporter.resources.requests.cpu | string | `"25m"` |  |
| metrics.exporter.resources.requests.memory | string | `"64Mi"` |  |
| metrics.port | int | `9628` |  |
| metrics.prometheusRule.defaults.downFor | string | `"10m"` |  |
| metrics.prometheusRule.defaults.printerStoppedFor | string | `"15m"` |  |
| metrics.prometheusRule.defaults.queueStuckFor | string | `"30m"` |  |
| metrics.prometheusRule.defaults.queueStuckSeconds | int | `1800` |  |
| metrics.prometheusRule.enabled | bool | `false` |  |
| metrics.prometheusRule.labels | object | `{}` |  |
| metrics.prometheusRule.namespace | string | `""` |  |
| metrics.prometheusRule.rules | list | `[]` | Set to a list to fully replace the default rules |
| metrics.serviceMonitor.annotations | object | `{}` |  |
| metrics.serviceMonitor.enabled | bool | `false` |  |
| metrics.serviceMonitor.honorLabels | bool | `false` |  |
| metrics.serviceMonitor.interval | string | `"30s"` |  |
| metrics.serviceMonitor.labels | object | `{}` |  |
| metrics.serviceMonitor.metricRelabelings | list | `[]` |  |
| metrics.serviceMonitor.namespace | string | `""` |  |
| metrics.serviceMonitor.relabelings | list | `[]` |  |
| metrics.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| metrics.vmServiceScrape.annotations | object | `{}` |  |
| metrics.vmServiceScrape.enabled | bool | `false` |  |
| metrics.vmServiceScrape.interval | string | `"30s"` |  |
| metrics.vmServiceScrape.labels | object | `{}` |  |
| metrics.vmServiceScrape.metricRelabelConfigs | list | `[]` |  |
| metrics.vmServiceScrape.namespace | string | `""` |  |
| metrics.vmServiceScrape.relabelConfigs | list | `[]` |  |
| metrics.vmServiceScrape.scrapeTimeout | string | `"10s"` |  |
| nameOverride | string | `""` | Override the chart name portion of resource names |
| networkPolicy.allowFrom | list | `[]` | Ingress sources allowed to reach :631 |
| networkPolicy.egress | object | `{"allowDNS":true,"enabled":true,"to":[]}` | Egress rules. Printers usually live outside the cluster CIDR. |
| networkPolicy.enabled | bool | `false` |  |
| networkPolicy.monitoringNamespaceSelector | object | `{"matchLabels":{"kubernetes.io/metadata.name":"monitoring"}}` | Allow scraping from the monitoring namespace |
| nodeSelector | object | `{}` |  |
| persistence.config | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"existingClaim":"","size":"1Gi","storageClass":""}` | /etc/cups: queue definitions, PPDs, certs |
| persistence.enabled | bool | `true` |  |
| persistence.retentionPolicy | object | `{"whenDeleted":"Retain","whenScaled":"Retain"}` | Keep PVCs when the StatefulSet is deleted |
| persistence.spool | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"existingClaim":"","size":"5Gi","storageClass":""}` | /var/spool/cups: job spool. Size for your largest concurrent job set. |
| plugins.debs | list | `[]` | Vendor .deb URLs with mandatory sha256 (e.g. Canon cnijfilter2) |
| plugins.enabled | bool | `false` | Install extra driver packages/blobs at pod start into a shared emptyDir.    Reliable path is baking them into the image (see the image repo build    args); use this only when you cannot rebuild. |
| plugins.extraVolumeMounts | list | `[]` |  |
| plugins.extraVolumes | list | `[]` | Pre-staged plugin artifacts from an existing PVC/ConfigMap/Secret |
| plugins.image | object | `{"pullPolicy":"IfNotPresent","registry":"docker.io","repository":"debian","tag":"bookworm-slim"}` | Init container image used to fetch/extract packages |
| plugins.packages | list | `[]` | apt packages installed into the plugin overlay (requires egress + a mirror) |
| plugins.resources.limits.memory | string | `"512Mi"` |  |
| plugins.resources.requests.cpu | string | `"50m"` |  |
| plugins.resources.requests.memory | string | `"64Mi"` |  |
| podAnnotations | object | `{}` |  |
| podDisruptionBudget.enabled | bool | `false` |  |
| podDisruptionBudget.minAvailable | int | `0` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| podSecurityContext.runAsGroup | int | `1000` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `1000` |  |
| podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| podSecurityContext.supplementalGroups[0] | int | `7` |  |
| printers | list | `[]` | Declarative print queues. Reconciled on every pod start via lpadmin.    `model` accepts an `everywhere`/`drv:///` spec; `ppd` points at a file    provided through `extraPPDs` or a plugin. |
| priorityClassName | string | `""` |  |
| readinessProbe.enabled | bool | `true` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.timeoutSeconds | int | `5` |  |
| replicaCount | int | `1` | CUPS is a stateful singleton (spool + config on one RWO volume). Do not raise. |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.privileged | bool | `false` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| service.annotations | object | `{}` |  |
| service.clusterIP | string | `""` |  |
| service.externalTrafficPolicy | string | `""` |  |
| service.extra | object | `{"annotations":{},"enabled":false,"type":"LoadBalancer"}` | Additional Service exposing IPP on a LoadBalancer for printers/clients    that cannot traverse the Ingress (raw IPP, port 631 without a Host header). |
| service.labels | object | `{}` |  |
| service.loadBalancerIP | string | `""` |  |
| service.loadBalancerSourceRanges | list | `[]` |  |
| service.nodePort | string | `nil` |  |
| service.port | int | `631` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automountServiceAccountToken | bool | `false` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| startupProbe.enabled | bool | `true` |  |
| startupProbe.failureThreshold | int | `30` |  |
| startupProbe.periodSeconds | int | `5` |  |
| terminationGracePeriodSeconds | int | `60` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |
| updateStrategy.rollingUpdate.partition | int | `0` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |
| usbPrinters.enabled | bool | `false` | Mount /dev/bus/usb from the node. Requires the pod to land on the node    with the printer attached - pair with nodeSelector/affinity. |
| usbPrinters.hostPath | string | `"/dev/bus/usb"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
