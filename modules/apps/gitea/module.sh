#!/usr/bin/env bash
# Gitea (requires docker). Uses SQLite by default.

MODULE_ID="gitea"
MODULE_TITLE="Gitea"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists gitea
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "gitea exists"; else log_plan "Will run gitea/gitea"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create gitea_data >/dev/null
  docker run -d \
    --name gitea \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_GITEA_HTTP_PORT:-3030}:3000" \
    -p "${SI_GITEA_SSH_PORT:-2222}:22" \
    -e "USER_UID=1000" \
    -e "USER_GID=1000" \
    -v gitea_data:/data \
    gitea/gitea:1.22
}

module_verify() { module_check; }
