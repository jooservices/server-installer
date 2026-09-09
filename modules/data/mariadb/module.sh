#!/usr/bin/env bash
# MariaDB (requires docker). Mutex with mysql.

MODULE_ID="mariadb"
MODULE_TITLE="MariaDB"

module_check() {
  if [[ "${SI_OS_FAMILY}" == "macos" ]]; then
    si_pkg_is_installed mariadb
    return
  fi
  command -v docker >/dev/null 2>&1 && si_docker_container_exists mariadb
}

module_plan() {
  if [[ "${SI_OS_FAMILY}" == "macos" ]]; then
    if module_check; then log_plan "mariadb (brew) already installed"; else log_plan "Will brew install mariadb"; fi
    return
  fi
  local panel
  if panel="$(si_installed_panel)"; then
    log_plan "${panel} detected — mariadb will refuse (mutex, panel owns the DB stack)"
  fi
  if si_docker_container_exists mysql 2>/dev/null; then
    log_plan "MySQL detected — mariadb will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "mariadb exists"; else log_plan "Will run mariadb:11"; fi
}

module_apply() {
  if [[ "${SI_OS_FAMILY}" == "macos" ]]; then
    if module_check; then return 0; fi
    if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
    si_pkg_install mariadb
    si_brew_require || return 1
    brew services start mariadb >/dev/null 2>&1 || true
    log_warn "No root password set automatically — run 'mysql_secure_installation' to secure it"
    return 0
  fi
  local panel
  if panel="$(si_installed_panel)"; then
    log_error "${panel} is installed. It manages the DB stack itself — remove it before installing MariaDB."
    return 1
  fi
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
