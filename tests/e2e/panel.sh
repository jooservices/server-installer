#!/usr/bin/env bash
# E2E: Webmin (mutex partners virtualmin + the web stack).
# Virtualmin's own install is a heavy interactive-mail-stack affair and is
# exercised via `doctor`/mutex checks only, not a live install, to keep this
# suite fast and non-flaky in CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true

echo "=== E2E panel: apply webmin ==="
"${ROOT}/bin/server-installer" apply --modules webmin
assert_cmd "webmin package present" dpkg -s webmin

echo "=== E2E panel: mutex refuses apache alongside webmin ==="
if "${ROOT}/bin/server-installer" apply --modules apache >/tmp/si-panel-mutex.txt 2>&1; then
  echo "[FAIL] apache should have refused with webmin installed" >&2
  cat /tmp/si-panel-mutex.txt >&2
  exit 1
fi
assert_cmd "apache still absent" bash -c "! command -v apache2 >/dev/null 2>&1"
echo "[PASS] apache refused (mutex)"

echo "=== E2E panel: virtualmin refuses alongside webmin ==="
# Real apply (not --dry-run): the mutex check runs before any download/
# side effect in module_apply, so this is still safe and instant — plan
# mode never fails on its own (it's report-only), so this must be a real
# apply to actually exercise the refusal.
if "${ROOT}/bin/server-installer" apply --modules virtualmin >/tmp/si-panel-virtualmin.txt 2>&1; then
  echo "[FAIL] virtualmin should have refused with webmin installed" >&2
  cat /tmp/si-panel-virtualmin.txt >&2
  exit 1
fi
assert_cmd "virtualmin error mentions webmin mutex" bash -c "grep -qi 'webmin' /tmp/si-panel-virtualmin.txt"
echo "[PASS] virtualmin refused (mutex)"

echo "=== E2E panel: PASS ==="
