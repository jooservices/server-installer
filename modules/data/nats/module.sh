#!/usr/bin/env bash
# NATS (requires docker).

MODULE_ID="nats"
MODULE_TITLE="NATS"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists nats
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "nats exists"; else log_plan "Will run nats:2"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker run -d \
    --name nats \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_NATS_PORT:-4222}:4222" \
    -p "${SI_NATS_MONITOR_PORT:-8222}:8222" \
    nats:2 \
    -js -m 8222
}

module_verify() { module_check; }
