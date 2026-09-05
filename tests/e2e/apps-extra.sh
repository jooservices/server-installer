#!/usr/bin/env bash
# E2E: extra docker apps (watchtower, NPM, postgres, redis, gitea, nextcloud, HA, crowdsec).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy
export SI_POSTGRES_PASSWORD=e2e-postgres-pass

echo "=== E2E apps-extra: docker ==="
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

echo "=== E2E apps-extra: apply ==="
"${ROOT}/bin/server-installer" apply --modules \
  watchtower,nginx_proxy_manager,postgres,redis,gitea,nextcloud,homeassistant,crowdsec,milvus

assert_docker_container "watchtower" watchtower
assert_docker_container "nginx-proxy-manager" nginx-proxy-manager
assert_docker_container "postgres" postgres
assert_docker_container "redis" redis
assert_docker_container "gitea" gitea
assert_docker_container "nextcloud" nextcloud
assert_docker_container "homeassistant" homeassistant
assert_docker_container "crowdsec" crowdsec
assert_docker_container "milvus" milvus

echo "=== E2E apps-extra: PASS ==="
