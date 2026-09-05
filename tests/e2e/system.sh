#!/usr/bin/env bash
# E2E: system modules from SSD parity.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_HOSTNAME=si-e2e-host
export SI_LOCALE=en_US.UTF-8
export SI_TIMEZONE=UTC
export SI_SWAP_SIZE=64M

echo "=== E2E system: apply ==="
"${ROOT}/bin/server-installer" apply --modules \
  hostname,locale,timezone,ulimits,supervisor,swap,upgrade

assert_cmd "hostname file" bash -c 'grep -qx si-e2e-host /etc/hostname'
assert_cmd "locale drop-in" bash -c 'grep -q en_US.UTF-8 /etc/default/locale'
assert_cmd "timezone" bash -c 'grep -qx UTC /etc/timezone || readlink /etc/localtime | grep -q UTC'
assert_cmd "ulimits conf" test -f /etc/security/limits.d/99-server-installer.conf
assert_cmd "sysctl conf" test -f /etc/sysctl.d/99-server-installer.conf
assert_cmd "supervisor" command -v supervisord
assert_cmd "swap active" bash -c 'swapon --show --noheadings | grep -q .'
assert_cmd "upgrade stamp" test -f /var/lib/server-installer/last-upgrade

echo "=== E2E system: PASS ==="
