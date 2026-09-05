#!/usr/bin/env bash
# E2E: wizard unattended path (frontend → CLI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_HOSTNAME=si-wizard-e2e
export SI_REPORT_DIR=/tmp/si-wizard-reports
rm -rf "${SI_REPORT_DIR}"
mkdir -p "${SI_REPORT_DIR}"

echo "=== E2E wizard: unattended packages+hostname ==="
"${ROOT}/bin/server-installer-wizard" \
  --unattended \
  --modules packages,hostname \
  --force \
  --no-whiptail

assert_cmd "hostname applied" bash -c 'grep -qx si-wizard-e2e /etc/hostname'
assert_cmd "wizard report written" bash -c 'ls -1 /tmp/si-wizard-reports/run-*.md | head -n1 | grep -q .'

echo "=== E2E wizard: preflight BLOCK without --force ==="
set +e
"${ROOT}/bin/server-installer-wizard" \
  --unattended \
  --modules fail2ban \
  --no-whiptail \
  --fresh
pf_rc=$?
set -e
assert_cmd "preflight blocks fail2ban without systemd" bash -c "test ${pf_rc} -eq 2"

echo "=== E2E wizard: mid-run resume ==="
export SI_WIZARD_STATE=/tmp/si-wizard-resume-state.json
export SI_HOSTNAME=si-wizard-resume
rm -f "${SI_WIZARD_STATE}"
python3 - <<'PY'
import json
state = {
    "stage": "review",
    "mode": "unattended",
    "profile": "",
    "modules": ["packages", "hostname"],
    "force_preflight": True,
    "env": {"SI_HOSTNAME": "si-wizard-resume"},
}
with open("/tmp/si-wizard-resume-state.json", "w", encoding="utf-8") as f:
    json.dump(state, f)
    f.write("\n")
PY
"${ROOT}/bin/server-installer-wizard" \
  --unattended \
  --resume \
  --force \
  --no-whiptail
assert_cmd "resume hostname" bash -c 'grep -qx si-wizard-resume /etc/hostname'
assert_cmd "resume cleared state" bash -c 'test ! -f /tmp/si-wizard-resume-state.json'

echo "=== E2E wizard: PASS ==="
