#!/usr/bin/env bash
# Redis (requires docker).

MODULE_ID="redis"
MODULE_TITLE="Redis"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists redis
}

module_plan() {
  if si_docker_container_exists valkey 2>/dev/null; then
    log_plan "Valkey detected — redis will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "redis exists"; else log_plan "Will run redis:7"; fi
}

module_apply() {
  si_docker_require || return 1
  if si_docker_container_exists valkey; then
    log_error "Valkey is installed. Remove it before installing Redis."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create redis_data >/dev/null
  docker run -d \
    --name redis \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_REDIS_PORT:-6379}:6379" \
    -v redis_data:/data \
    redis:7 \
    redis-server --appendonly yes
}

module_verify() { module_check; }
