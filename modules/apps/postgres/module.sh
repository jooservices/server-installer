#!/usr/bin/env bash
# PostgreSQL (requires docker).

MODULE_ID="postgres"
MODULE_TITLE="PostgreSQL"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists postgres
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "postgres exists"; else log_plan "Will run postgres:16"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local pass net
  pass="${SI_POSTGRES_PASSWORD:-}"
  if [[ -z "${pass}" ]]; then
    pass="$(si_random_secret 16)"
    log_warn "Generated Postgres password (set SI_POSTGRES_PASSWORD to pin): ${pass}"
  fi
  net="$(si_docker_ensure_network)"
  docker volume create postgres_data >/dev/null
  docker run -d \
    --name postgres \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_POSTGRES_PORT:-5432}:5432" \
    -e "POSTGRES_USER=${SI_POSTGRES_USER:-postgres}" \
    -e "POSTGRES_PASSWORD=${pass}" \
    -e "POSTGRES_DB=${SI_POSTGRES_DB:-postgres}" \
    -v postgres_data:/var/lib/postgresql/data \
    postgres:16
}

module_verify() { module_check; }
