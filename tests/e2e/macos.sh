#!/usr/bin/env bash
# E2E: macOS workstation modules (homebrew, oh_my_zsh, php/redis/mariadb/mongodb
# via brew). Real installs — meant to run on an actual macOS host/runner
# (e.g. GitHub Actions macos-latest), never inside a Linux Docker container.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "=== E2E macos: skipped (not running on Darwin) ==="
  exit 0
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "This suite must run as a normal user — Homebrew refuses root." >&2
  exit 1
fi

export SI_SKIP_LOCK=true
export SI_PHP_VERSION="${SI_PHP_VERSION:-8.5}"
export SI_PHP_MODE=fpm

echo "=== E2E macos: apply homebrew ==="
"${ROOT}/bin/server-installer" apply --modules homebrew
assert_cmd "brew binary" command -v brew

echo "=== E2E macos: apply oh_my_zsh ==="
"${ROOT}/bin/server-installer" apply --modules oh_my_zsh
assert_cmd "oh_my_zsh installed" test -d "${HOME}/.oh-my-zsh"

echo "=== E2E macos: apply php,redis,mariadb,mongodb (brew) ==="
"${ROOT}/bin/server-installer" apply --modules php,redis,mariadb,mongodb

assert_cmd "php (brew) installed" brew list --formula "shivammathur/php/php@${SI_PHP_VERSION}"
assert_cmd "redis (brew) installed" brew list --formula redis
assert_cmd "mariadb (brew) installed" brew list --formula mariadb
assert_cmd "mongodb-community (brew) installed" brew list --formula mongodb-community

echo "=== E2E macos: preflight is clean (no BLOCK) ==="
"${ROOT}/bin/server-installer" apply --modules redis --preflight --dry-run

echo "=== E2E macos: PASS ==="
