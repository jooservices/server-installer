#!/usr/bin/env bash
# MariaDB (requires docker). Mutex with mysql.

MODULE_ID="mariadb"
MODULE_TITLE="MariaDB"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists mariadb
}

module_plan() {
  if si_docker_container_exists mysql 2>/dev/null; then
    log_plan "MySQL detected — mariadb will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "mariadb exists"; else log_plan "Will run mariadb:11"; fi
}

module_apply() {
  si_docker_require || return 1
  if si_docker_container_exists mysql; then
    log_error "MySQL is installed. Remove it before installing MariaDB."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local pass net
  pass="${SI_MARIADB_ROOT_PASSWORD:-}"
  if [[ -z "${pass}" ]]; then
    pass="$(si_random_secret 16)"
    log_warn "Generated MariaDB root password (set SI_MARIADB_ROOT_PASSWORD to pin): ${pass}"
  fi
  net="$(si_docker_ensure_network)"
  docker volume create mariadb_data >/dev/null
  docker run -d \
    --name mariadb \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_MARIADB_PORT:-3306}:3306" \
    -e "MARIADB_ROOT_PASSWORD=${pass}" \
    -e "MARIADB_DATABASE=${SI_MARIADB_DATABASE:-app}" \
    -e "MARIADB_USER=${SI_MARIADB_USER:-app}" \
    -e "MARIADB_PASSWORD=${SI_MARIADB_PASSWORD:-${pass}}" \
    -v mariadb_data:/var/lib/mysql \
    mariadb:11
}

module_verify() { module_check; }
