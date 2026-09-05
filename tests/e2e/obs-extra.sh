#!/usr/bin/env bash
# E2E: zipkin, tempo, pyroscope, nightingale, signoz.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy

echo "=== E2E obs-extra: docker ==="
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

echo "=== E2E obs-extra: apply ==="
"${ROOT}/bin/server-installer" apply --modules \
  zipkin,tempo,pyroscope,nightingale,signoz

assert_docker_container "zipkin" zipkin
assert_docker_container "tempo" tempo
assert_docker_container "pyroscope" pyroscope
assert_docker_container "nightingale" nightingale
assert_docker_container "signoz-frontend" signoz-frontend

echo "=== E2E obs-extra: PASS ==="
