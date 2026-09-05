#!/usr/bin/env bash
# Home Assistant (requires docker).

MODULE_ID="homeassistant"
MODULE_TITLE="Home Assistant"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists homeassistant
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "homeassistant exists"; else log_plan "Will run home-assistant image"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create homeassistant_config >/dev/null
  docker run -d \
    --name homeassistant \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_HOMEASSISTANT_PORT:-8123}:8123" \
    -e "TZ=${SI_TZ:-UTC}" \
    -v homeassistant_config:/config \
    ghcr.io/home-assistant/home-assistant:stable
}

module_verify() { module_check; }
