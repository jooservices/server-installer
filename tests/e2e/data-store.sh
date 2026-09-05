#!/usr/bin/env bash
# E2E: data stores (mariadb, mongodb, clickhouse, memcached, brokers).
# mysql and valkey are mutex partners — covered in separate suites.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy
export SI_MARIADB_ROOT_PASSWORD=e2e-mariadb-pass
export SI_MONGODB_ROOT_PASSWORD=e2e-mongo-pass

echo "=== E2E data-store: docker ==="
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

echo "=== E2E data-store: apply ==="
"${ROOT}/bin/server-installer" apply --modules \
  mariadb,mongodb,clickhouse,memcached,rabbitmq,nats,kafka,mosquitto

assert_docker_container "mariadb" mariadb
assert_docker_container "mongodb" mongodb
assert_docker_container "clickhouse" clickhouse
assert_docker_container "memcached" memcached
assert_docker_container "rabbitmq" rabbitmq
assert_docker_container "nats" nats
assert_docker_container "kafka" kafka
assert_docker_container "mosquitto" mosquitto

echo "=== E2E data-store: PASS ==="
