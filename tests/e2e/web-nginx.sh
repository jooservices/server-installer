#!/usr/bin/env bash
# E2E: nginx + PHP-FPM composed via --modules (no profile).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_PHP_VERSION="${SI_PHP_VERSION:-8.5}"
export SI_PHP_MODE=fpm

echo "=== E2E web-nginx: apply nginx,php ==="
"${ROOT}/bin/server-installer" apply --modules nginx,php

echo "=== E2E web-nginx: assertions ==="
assert_cmd "nginx binary" command -v nginx
assert_cmd "nginx -t" nginx -t
assert_cmd "php binary" command -v php
assert_cmd "php version ${SI_PHP_VERSION}" bash -c "php -v | head -n1 | grep -F 'PHP ${SI_PHP_VERSION}' >/dev/null"
assert_cmd "fpm package present" dpkg -s "php${SI_PHP_VERSION}-fpm"
assert_cmd "apache not installed" bash -c "! command -v apache2 >/dev/null 2>&1"

echo "=== E2E web-nginx: PASS ==="
