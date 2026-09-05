#!/usr/bin/env bash
# E2E: PHP CLI only (no FPM, no web server).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_PHP_VERSION="${SI_PHP_VERSION:-8.5}"
export SI_PHP_MODE=cli

echo "=== E2E php-cli: apply ==="
"${ROOT}/bin/server-installer" apply --modules php

echo "=== E2E php-cli: assertions ==="
assert_cmd "php binary" command -v php
assert_cmd "php version ${SI_PHP_VERSION}" bash -c "php -v | head -n1 | grep -F 'PHP ${SI_PHP_VERSION}' >/dev/null"
assert_cmd "fpm package absent" bash -c "! dpkg -s php${SI_PHP_VERSION}-fpm >/dev/null 2>&1"
assert_cmd "nginx absent" bash -c '! command -v nginx >/dev/null 2>&1'

echo "=== E2E php-cli: idempotent re-apply ==="
"${ROOT}/bin/server-installer" apply --modules php

echo "=== E2E php-cli: PASS ==="
