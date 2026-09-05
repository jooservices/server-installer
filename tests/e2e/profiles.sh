#!/usr/bin/env bash
# E2E: profile schema B (modules + env defaults).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"
# shellcheck source=../../lib/common.sh
source "${ROOT}/lib/common.sh"
si_bootstrap

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy
export SI_MYSQL_ROOT_PASSWORD=e2e-mysql-pass

echo "=== E2E profiles: JSON schema ==="
SI_PROFILES_DIR="${SI_PROFILES_DIR}" python3 - <<'PY'
import json, os, sys
from pathlib import Path
root = Path(os.environ["SI_PROFILES_DIR"])
required = {
    "vm-essentials", "vm-docker", "web-lamp", "web-lemp", "sec-baseline", "obs-lite",
}
found = {p.stem for p in root.glob("*.json")}
missing = required - found
if missing:
    print("missing profiles:", sorted(missing), file=sys.stderr)
    sys.exit(1)
for name in sorted(required):
    data = json.loads((root / f"{name}.json").read_text(encoding="utf-8"))
    assert isinstance(data.get("modules"), list) and data["modules"], name
    assert isinstance(data.get("env"), dict), name
    if name.startswith("web-"):
        assert data["env"].get("SI_PHP_VERSION") == "8.5", name
print("schema ok")
PY

echo "=== E2E profiles: env apply / no override ==="
unset SI_PHP_VERSION SI_PHP_MODE || true
si_profile_apply_env web-lemp
assert_cmd "profile sets PHP 8.5" bash -c 'test "${SI_PHP_VERSION}" = "8.5"'
assert_cmd "profile sets fpm" bash -c 'test "${SI_PHP_MODE}" = "fpm"'

export SI_PHP_VERSION=8.4
si_profile_apply_env web-lemp
assert_cmd "explicit env wins" bash -c 'test "${SI_PHP_VERSION}" = "8.4"'
unset SI_PHP_VERSION SI_PHP_MODE

echo "=== E2E profiles: doctor presets ==="
"${ROOT}/bin/server-installer" doctor --profile web-lamp >/tmp/si-doctor-lamp.txt 2>&1
assert_cmd "doctor web-lamp mentions Apache" bash -c 'grep -qi apache /tmp/si-doctor-lamp.txt'
"${ROOT}/bin/server-installer" doctor --profile sec-baseline >/dev/null
"${ROOT}/bin/server-installer" doctor --profile obs-lite >/dev/null

echo "=== E2E profiles: docker engine ==="
"${ROOT}/bin/server-installer" apply --modules docker,docker_group
if ! docker info >/dev/null 2>&1; then
  pkill dockerd >/dev/null 2>&1 || true
  sleep 1
  dockerd --storage-driver=vfs >/var/log/dockerd.log 2>&1 &
  for _ in $(seq 1 45); do
    docker info >/dev/null 2>&1 && break
    sleep 1
  done
fi
assert_cmd "docker info" docker info

echo "=== E2E profiles: apply web-lemp ==="
unset SI_PHP_VERSION SI_PHP_MODE || true
"${ROOT}/bin/server-installer" apply --profile web-lemp

assert_cmd "nginx present" command -v nginx
assert_cmd "php 8.5 from profile" bash -c "php -v | head -n1 | grep -F 'PHP 8.5' >/dev/null"
assert_cmd "php-fpm from profile" dpkg -s php8.5-fpm
assert_docker_container "mysql" mysql

echo "=== E2E profiles: PASS ==="
