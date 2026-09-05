#!/usr/bin/env bash
# E2E: install-only CM agents (Salt/Puppet/Chef/CFEngine).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy

echo "=== E2E iac-cm: apply ==="
"${ROOT}/bin/server-installer" apply --modules salt,puppet,chef,cfengine

assert_cmd "salt" bash -c 'command -v salt-call || command -v salt-minion'
assert_cmd "puppet" command -v puppet
assert_cmd "chef/cinc" bash -c 'command -v cinc-client || command -v chef-client'
assert_cmd "cfengine" bash -c 'command -v cf-agent || command -v cf-promises'

echo "=== E2E iac-cm: PASS ==="
