git switch --orphan gh-pages
git rm -rf . 2>/dev/null; rm -rf charts .github

cat > README.md <<'EOF'
# cups-server Helm Chart

Unprivileged CUPS 2.4 print server for Kubernetes.

```bash
helm repo add cups-server https://silentvoltage.github.io/cups-server-helm
helm repo update
helm install printing cups-server/cups-server -n printing --create-namespace
```

OCI: `oci://ghcr.io/silentvoltage/charts/cups-server`

Source & docs: https://github.com/SilentVoltage/cups-server-helm
EOF

cat > _config.yml <<'EOF'
title: cups-server Helm Chart
description: Unprivileged CUPS 2.4 print server for Kubernetes
EOF

git add . && git commit -m "init gh-pages" && git push -u origin gh-pages
git switch master