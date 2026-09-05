#!/usr/bin/env bash
# E2E: caddy, loki, promtail, firewall, tailscale (no Docker apps).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true

echo "=== E2E gap-sys: apply ==="
"${ROOT}/bin/server-installer" apply --modules caddy,loki,promtail,firewall,tailscale

assert_cmd "caddy" command -v caddy
assert_cmd "loki" command -v loki
assert_cmd "promtail" command -v promtail
assert_cmd "ufw" command -v ufw
assert_cmd "ufw active" bash -c 'ufw status | grep -i "Status: active" >/dev/null'
assert_cmd "tailscale" command -v tailscale
assert_cmd "tailscaled" command -v tailscaled

echo "=== E2E gap-sys: PASS ==="
