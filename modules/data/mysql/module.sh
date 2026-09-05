#!/usr/bin/env bash
# MySQL (requires docker). Mutex with mariadb.

MODULE_ID="mysql"
MODULE_TITLE="MySQL"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists mysql
}

module_plan() {
  if si_docker_container_exists mariadb 2>/dev/null; then
    log_plan "MariaDB detected — mysql will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "mysql exists"; else log_plan "Will run mysql:8.4"; fi
}

module_apply() {
  si_docker_require || return 1
  if si_docker_container_exists mariadb; then
    log_error "MariaDB is installed. Remove it before installing MySQL."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local pass net
  pass="${SI_MYSQL_ROOT_PASSWORD:-}"
  if [[ -z "${pass}" ]]; then
    pass="$(si_random_secret 16)"
    log_warn "Generated MySQL root password (set SI_MYSQL_ROOT_PASSWORD to pin): ${pass}"
  fi
  net="$(si_docker_ensure_network)"
  docker volume create mysql_data >/dev/null
  docker run -d \
    --name mysql \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_MYSQL_PORT:-3306}:3306" \
    -e "MYSQL_ROOT_PASSWORD=${pass}" \
    -e "MYSQL_DATABASE=${SI_MYSQL_DATABASE:-app}" \
    -e "MYSQL_USER=${SI_MYSQL_USER:-app}" \
    -e "MYSQL_PASSWORD=${SI_MYSQL_PASSWORD:-${pass}}" \
    -v mysql_data:/var/lib/mysql \
    mysql:8.4
}

module_verify() { module_check; }
