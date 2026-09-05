#!/usr/bin/env bash
# Apache httpd. Independent of PHP (compose via --modules).

MODULE_ID="apache"
MODULE_TITLE="Apache"

si_apache_bin() {
  if command -v apache2 >/dev/null 2>&1; then
    printf 'apache2\n'
  elif command -v httpd >/dev/null 2>&1; then
    printf 'httpd\n'
  else
    printf '\n'
  fi
}

si_apache_pkg() {
  case "${SI_OS_FAMILY}" in
    debian) printf 'apache2\n' ;;
    redhat) printf 'httpd\n' ;;
    *) printf 'apache2\n' ;;
  esac
}

si_apache_unit() {
  case "${SI_OS_FAMILY}" in
    debian) printf 'apache2\n' ;;
    redhat) printf 'httpd\n' ;;
    *) printf 'apache2\n' ;;
  esac
}

module_check() {
  [[ -n "$(si_apache_bin)" ]]
}

module_plan() {
  if command -v nginx >/dev/null 2>&1; then
    if [[ "${SI_FORCE_BOTH_WEBSERVERS:-false}" != "true" ]]; then
      log_plan "Nginx detected — apache will refuse unless SI_FORCE_BOTH_WEBSERVERS=true"
    else
      log_plan "Nginx detected but SI_FORCE_BOTH_WEBSERVERS=true"
    fi
  fi
  if module_check; then
    log_plan "Apache already installed"
  else
    log_plan "Will install $(si_apache_pkg) via ${SI_PKG_MANAGER}"
  fi
}

module_apply() {
  if command -v nginx >/dev/null 2>&1; then
    if [[ "${SI_FORCE_BOTH_WEBSERVERS:-false}" != "true" ]]; then
      log_error "Nginx is installed. Uninstall it or set SI_FORCE_BOTH_WEBSERVERS=true"
      return 1
    fi
  fi

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  if ! module_check; then
    si_pkg_install "$(si_apache_pkg)"
  fi

  local unit
  unit="$(si_apache_unit)"
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl enable "${unit}" >/dev/null 2>&1 || true
    systemctl restart "${unit}" >/dev/null 2>&1 || systemctl start "${unit}" >/dev/null 2>&1 || true
  elif command -v service >/dev/null 2>&1; then
    service "${unit}" start >/dev/null 2>&1 || true
  fi
}

module_verify() {
  [[ -n "$(si_apache_bin)" ]]
}
