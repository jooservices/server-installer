#!/usr/bin/env bash
# E2E: docker engine + docker-backed apps (portainer, kuma, minio, traefik, pihole).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy

echo "=== E2E gap-apps: docker ==="
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

echo "=== E2E gap-apps: containers ==="
"${ROOT}/bin/server-installer" apply --modules portainer,uptime_kuma,minio,traefik,pihole

assert_docker_container "portainer container" portainer
assert_docker_container "uptime-kuma container" uptime-kuma
assert_docker_container "minio container" minio
assert_docker_container "traefik container" traefik
assert_docker_container "pihole container" pihole
id -nG deploy | tr ' ' '\n' | assert_line "deploy in docker group" docker

# Prefer running state when possible
assert_docker_container "portainer running" portainer running
assert_docker_container "minio running" minio running

echo "=== E2E gap-apps: PASS ==="
