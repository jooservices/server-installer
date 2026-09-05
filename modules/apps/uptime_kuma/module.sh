#!/usr/bin/env bash
# Uptime Kuma (requires docker).

MODULE_ID="uptime_kuma"
MODULE_TITLE="Uptime Kuma"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists uptime-kuma
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "uptime-kuma exists"; else log_plan "Will run louislam/uptime-kuma"; fi
}

module_apply() {
  if ! command -v docker >/dev/null 2>&1; then log_error "Docker required"; return 1; fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  docker volume create uptime_kuma_data >/dev/null
  docker run -d \
    --name uptime-kuma \
    --restart=unless-stopped \
    -p "${SI_UPTIME_KUMA_PORT:-3001}:3001" \
    -v uptime_kuma_data:/app/data \
    louislam/uptime-kuma:1
}

module_verify() { module_check; }
