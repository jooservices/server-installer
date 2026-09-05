#!/usr/bin/env bash
# Portainer CE (requires docker module).

MODULE_ID="portainer"
MODULE_TITLE="Portainer"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists portainer
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then
    log_plan "Docker required — install docker module first"
  fi
  if module_check; then log_plan "Portainer container exists"; else log_plan "Will run portainer/portainer-ce"; fi
}

module_apply() {
  if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker not installed. Apply module docker first."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  docker volume create portainer_data >/dev/null
  docker run -d \
    --name portainer \
    --restart=unless-stopped \
    -p "${SI_PORTAINER_PORT:-9000}:9000" \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
}

module_verify() { module_check; }
