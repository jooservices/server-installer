#!/usr/bin/env bash
# Virtualmin (official install.sh; hosting panel built on Webmin — installs
# Apache/Nginx + PHP + MariaDB + mail/DNS itself).
# Bundle via SI_VIRTUALMIN_BUNDLE=LAMP|LEMP (default LAMP).
# Type via SI_VIRTUALMIN_TYPE=full|mini (default full; mini skips mail/spam/AV).
# Mutex: refuses if apache/nginx/php/mariadb/mysql/certbot/haproxy/caddy/
# traefik/nginx_proxy_manager/adguard/pihole/webmin is present.

MODULE_ID="virtualmin"
MODULE_TITLE="Virtualmin"

SI_VIRTUALMIN_BUNDLE="${SI_VIRTUALMIN_BUNDLE:-LAMP}"
SI_VIRTUALMIN_TYPE="${SI_VIRTUALMIN_TYPE:-full}"

module_check() {
  command -v virtualmin >/dev/null 2>&1
}

si_virtualmin_conflict() {
  if si_pkg_is_installed webmin 2>/dev/null; then
    printf 'webmin\n'
    return 0
  fi
  si_panel_conflict
}

module_plan() {
  local conflict
  if conflict="$(si_virtualmin_conflict)"; then
    log_plan "${conflict} detected — virtualmin will refuse (mutex, panel owns the web stack)"
  fi
  if module_check; then
    log_plan "Virtualmin already installed"
  else
    log_plan "Will install Virtualmin (bundle=${SI_VIRTUALMIN_BUNDLE} type=${SI_VIRTUALMIN_TYPE}) via official install.sh"
  fi
}

module_apply() {
  case "${SI_VIRTUALMIN_BUNDLE}" in
    LAMP|LEMP) ;;
    *)
      log_error "SI_VIRTUALMIN_BUNDLE must be LAMP or LEMP (got: ${SI_VIRTUALMIN_BUNDLE})"
      return 1
      ;;
  esac
  case "${SI_VIRTUALMIN_TYPE}" in
    full|mini) ;;
    *)
      log_error "SI_VIRTUALMIN_TYPE must be full or mini (got: ${SI_VIRTUALMIN_TYPE})"
      return 1
      ;;
  esac

  local conflict
  if conflict="$(si_virtualmin_conflict)"; then
    log_error "${conflict} is installed. Virtualmin manages the web stack (and Webmin) itself — remove it first."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl
  local script="/tmp/virtualmin-install.sh"
  si_download "https://download.virtualmin.com/virtualmin-install.sh" "${script}"

  local args=(--bundle "${SI_VIRTUALMIN_BUNDLE}" --type "${SI_VIRTUALMIN_TYPE}" --yes)
  [[ -n "${SI_VIRTUALMIN_HOSTNAME:-}" ]] && args+=(--hostname "${SI_VIRTUALMIN_HOSTNAME}")
  # installer writes its own log relative to CWD — run from a writable dir
  # regardless of where server-installer was invoked from.
  (cd /tmp && sh "${script}" "${args[@]}")
}

module_verify() { module_check; }
