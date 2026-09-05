#!/usr/bin/env bash
# Valkey (Redis-compatible). Mutex with redis.

MODULE_ID="valkey"
MODULE_TITLE="Valkey"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists valkey
}

module_plan() {
  if si_docker_container_exists redis 2>/dev/null; then
    log_plan "Redis detected — valkey will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "valkey exists"; else log_plan "Will run valkey/valkey:8"; fi
}

module_apply() {
  si_docker_require || return 1
  if si_docker_container_exists redis; then
    log_error "Redis is installed. Remove it before installing Valkey."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create valkey_data >/dev/null
  docker run -d \
    --name valkey \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_VALKEY_PORT:-6380}:6379" \
    -v valkey_data:/data \
    valkey/valkey:8 \
    valkey-server --appendonly yes
}

module_verify() { module_check; }
