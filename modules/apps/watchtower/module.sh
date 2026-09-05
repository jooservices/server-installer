#!/usr/bin/env bash
# Watchtower — auto-update running containers (requires docker).

MODULE_ID="watchtower"
MODULE_TITLE="Watchtower"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists watchtower
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "watchtower exists"; else log_plan "Will run containrrr/watchtower"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  docker run -d \
    --name watchtower \
    --restart=unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e "WATCHTOWER_CLEANUP=${SI_WATCHTOWER_CLEANUP:-true}" \
    -e "WATCHTOWER_POLL_INTERVAL=${SI_WATCHTOWER_POLL_INTERVAL:-86400}" \
    containrrr/watchtower
}

module_verify() { module_check; }
