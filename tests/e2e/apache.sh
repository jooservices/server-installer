#!/usr/bin/env bash
# E2E: apache module only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true

echo "=== E2E apache: apply ==="
"${ROOT}/bin/server-installer" apply --modules apache

echo "=== E2E apache: assertions ==="
assert_cmd "apache2 binary" command -v apache2
assert_cmd "nginx not installed" bash -c "! command -v nginx >/dev/null 2>&1"

echo "=== E2E apache: PASS ==="
