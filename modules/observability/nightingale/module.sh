#!/usr/bin/env bash
# Nightingale (n9e) monitoring. Requires docker.

MODULE_ID="nightingale"
MODULE_TITLE="Nightingale"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists nightingale
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "nightingale exists"; else log_plan "Will run flashcatcloud/nightingale"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create nightingale_data >/dev/null
  docker run -d \
    --name nightingale \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_NIGHTINGALE_PORT:-17000}:17000" \
    -v nightingale_data:/app/etc \
    "${SI_NIGHTINGALE_IMAGE:-flashcatcloud/nightingale:latest}"
}

module_verify() { module_check; }
