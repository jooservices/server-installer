#!/usr/bin/env bash
# E2E: package / binary DevOps modules (no pihole/adguard/firewall/docker-apps).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true

MODULES="fail2ban,haproxy,certbot,restic,borg,wireguard,node_exporter,prometheus,grafana,vault"

echo "=== E2E devops: apply ${MODULES} ==="
"${ROOT}/bin/server-installer" apply --modules "${MODULES}"

echo "=== E2E devops: assertions ==="
assert_cmd "fail2ban" command -v fail2ban-client
assert_cmd "jail.local" test -f /etc/fail2ban/jail.local
assert_cmd "haproxy" command -v haproxy
assert_cmd "certbot" command -v certbot
assert_cmd "restic" command -v restic
assert_cmd "borg" command -v borg
assert_cmd "wg" command -v wg
assert_cmd "node_exporter" command -v node_exporter
assert_cmd "prometheus" command -v prometheus
assert_cmd "grafana" bash -c 'command -v grafana-server || command -v grafana'
assert_cmd "vault" command -v vault

echo "=== E2E devops: PASS ==="
