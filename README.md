# cups-server-helm

Helm chart for [cups-server][image] — an unprivileged [CUPS][cups] 2.4 print
server for Kubernetes. Runs the scheduler as a `StatefulSet` with a read-only
root filesystem as uid/gid 1000, alongside an optional Prometheus exporter and a
`cups-browsed` / Avahi discovery sidecar. PVCs back the writable CUPS paths,
queues can be declared in values and reconciled on every pod start, and driver
plugins can be layered in at build time (in the image) or at pod start.

Published to:

- **OCI:** `oci://ghcr.io/silentvoltage/charts/cups-server`
- **Classic repo (gh-pages):** `https://silentvoltage.github.io/cups-server-helm`

The container image lives in the companion repo
[silentvoltage/cups-server-docker][image].

## Quick start

```sh
helm install printing oci://ghcr.io/silentvoltage/charts/cups-server \
  -n printing --create-namespace
```

Or add the classic repo:

```sh
helm repo add cups-server https://silentvoltage.github.io/cups-server-helm
helm install printing cups-server/cups-server -n printing --create-namespace
```

With no Ingress, reach the web UI through a port-forward:

```sh
kubectl -n printing port-forward svc/printing-cups-server 6631:631
# open http://127.0.0.1:6631/
```

## What it deploys

| Object | When |
|---|---|
| `StatefulSet` (scheduler + optional exporter/discovery/avahi sidecars) | always |
| `Service` (ClusterIP :631), optional extra `LoadBalancer` Service | always / `service.extra.enabled` |
| `PersistentVolumeClaim` for `/etc/cups` and `/var/spool/cups` | `persistence.enabled` (default) |
| `Secret` with the admin credentials | `auth.mode` != `none` and no `existingSecret` |
| `Ingress` (nginx/traefik basic-auth wiring) | `ingress.enabled` |
| `NetworkPolicy` | `networkPolicy.enabled` |
| `ServiceMonitor` / `VMServiceScrape` / `PrometheusRule` | respective `metrics.*.enabled` |
| `PodDisruptionBudget`, `ServiceAccount` | `podDisruptionBudget.enabled` / `serviceAccount.create` |

`replicaCount` is fixed at 1 — cupsd is a singleton over an RWO spool volume.

## Key values

| Key | Default | Notes |
|---|---|---|
| `image.registry` / `image.repository` | `ghcr.io` / `silentvoltage/cups-server` | swap `registry` to `docker.io` for the mirror; prefer pinning `image.digest` |
| `auth.mode` | `none` | `none` \| `ingress` (auth at the Ingress only) \| `cups` (cupsd enforces Basic auth via `pam_pwdfile`) |
| `auth.password` | generated | 24-char random on first install, kept in `<release>-auth` and reused on upgrades |
| `cups.serverAlias` | `*` | required behind an Ingress — cupsd returns HTTP 400 for unknown `Host` headers |
| `discovery.enabled` | `true` | `cups-browsed` sidecar; needs multicast reachability — see below |
| `discovery.browsePoll` | `[]` | unicast fallback: poll named CUPS/IPP hosts when mDNS is unroutable |
| `printers` | `[]` | declarative queues, reconciled via `lpadmin` on every pod start |
| `plugins.enabled` | `false` | install extra driver packages/blobs at pod start; baking into the image is the reliable path |
| `networkPolicy.enabled` | `false` | set `true` whenever `cups.allowFrom` is `all` |
| `persistence.config` / `persistence.spool` | `1Gi` / `5Gi` RWO | size the spool for your largest concurrent job set |

Full table: [`charts/cups-server/README.md`](charts/cups-server/README.md) (also on
ArtifactHub). Two ready-made value profiles live in
[`charts/cups-server/ci/`](charts/cups-server/ci/).

## Printer discovery

mDNS / DNS-SD only works on the pod's L2 segment and standard CNIs do not forward
multicast, so LAN discovery needs one of:

- `hostNetwork: true` (simplest; pins the pod to a node),
- a macvlan/ipvlan attachment via Multus (`extraPodAnnotations`), or
- `discovery.browsePoll` against a reachable CUPS/IPP host (no multicast).

Prefer driverless IPP Everywhere printers (`model: everywhere` under `printers`)
wherever the hardware supports it — no vendor filter, no PPD, no maintenance.

## Development

```sh
ct lint --config .github/ct.yaml
helm unittest charts/cups-server
helm template ci charts/cups-server -f charts/cups-server/ci/full-values.yaml \
  | kubeconform -strict -ignore-missing-schemas
helm-docs --chart-search-root=charts
```

CI ([`.github/workflows/chart.yaml`](.github/workflows/chart.yaml)) runs lint,
unit tests, kubeconform against every `ci/*-values.yaml` profile, a helm-docs
drift check, and `ct install` on a kind cluster for pull requests. Tags matching
`cups-server-*` publish the chart to GHCR as a cosign-signed OCI artifact and cut
a GitHub Release with `chart-releaser` (plus the classic gh-pages index).

## License

[Apache-2.0](LICENSE) — covers this repository's own sources (templates,
helpers, schema). The deployed **image** bundles CUPS, Ghostscript (AGPL-3.0),
Gutenprint and other GPL/AGPL components; see the
[image repo][image] for its redistribution notes and SBOM.

[cups]: https://openprinting.github.io/cups/
[image]: https://github.com/silentvoltage/cups-server-docker
