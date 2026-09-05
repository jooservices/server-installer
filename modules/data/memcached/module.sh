#!/usr/bin/env bash
# Memcached (requires docker).

MODULE_ID="memcached"
MODULE_TITLE="Memcached"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists memcached
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "memcached exists"; else log_plan "Will run memcached:1.6"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker run -d \
    --name memcached \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_MEMCACHED_PORT:-11211}:11211" \
    memcached:1.6 \
    memcached -m "${SI_MEMCACHED_MEMORY_MB:-64}"
}

module_verify() { module_check; }
