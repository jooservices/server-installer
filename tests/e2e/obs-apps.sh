#!/usr/bin/env bash
# E2E: sentry (GlitchTip) + jaeger + otel_collector.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy

echo "=== E2E obs-apps: docker ==="
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

echo "=== E2E obs-apps: apply ==="
"${ROOT}/bin/server-installer" apply --modules sentry,jaeger,otel_collector

assert_docker_container "glitchtip (sentry)" glitchtip
assert_docker_container "jaeger" jaeger
assert_docker_container "otel-collector" otel-collector

echo "=== E2E obs-apps: PASS ==="
