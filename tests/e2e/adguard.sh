#!/usr/bin/env bash
# E2E: AdGuard Home binary install (mutex partner pihole not installed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true

echo "=== E2E adguard: apply ==="
"${ROOT}/bin/server-installer" apply --modules adguard

assert_cmd "AdGuardHome binary" test -x /opt/AdGuardHome/AdGuardHome

echo "=== E2E adguard: PASS ==="
