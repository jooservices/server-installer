#!/usr/bin/env bash
# MongoDB (requires docker).

MODULE_ID="mongodb"
MODULE_TITLE="MongoDB"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists mongodb
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "mongodb exists"; else log_plan "Will run mongo:7"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net pass
  pass="${SI_MONGODB_ROOT_PASSWORD:-}"
  if [[ -z "${pass}" ]]; then
    pass="$(si_random_secret 16)"
    log_warn "Generated MongoDB root password (set SI_MONGODB_ROOT_PASSWORD to pin): ${pass}"
  fi
  net="$(si_docker_ensure_network)"
  docker volume create mongodb_data >/dev/null
  docker run -d \
    --name mongodb \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_MONGODB_PORT:-27017}:27017" \
    -e "MONGO_INITDB_ROOT_USERNAME=${SI_MONGODB_ROOT_USER:-root}" \
    -e "MONGO_INITDB_ROOT_PASSWORD=${pass}" \
    -v mongodb_data:/data/db \
    mongo:7
}

module_verify() { module_check; }
