#!/usr/bin/env bash
# Webmin (official webmin-setup-repo.sh). Standalone admin panel.
# Mutex: refuses if apache/nginx/php/mariadb/mysql/certbot/haproxy/caddy/
# traefik/nginx_proxy_manager/adguard/pihole/virtualmin is present — Webmin
# is meant to manage the web/DB stack itself once installed.

MODULE_ID="webmin"
MODULE_TITLE="Webmin"

module_check() {
  si_pkg_is_installed webmin
}

si_webmin_conflict() {
  if si_pkg_is_installed virtualmin-base 2>/dev/null || [[ -d /etc/virtualmin ]]; then
    printf 'virtualmin\n'
    return 0
  fi
  si_panel_conflict
}

module_plan() {
  local conflict
  if conflict="$(si_webmin_conflict)"; then
    log_plan "${conflict} detected — webmin will refuse (mutex, panel owns the web stack)"
  fi
  if module_check; then
    log_plan "Webmin already installed"
  else
    log_plan "Will install Webmin via official webmin-setup-repo.sh"
  fi
}

module_apply() {
  local conflict
  if conflict="$(si_webmin_conflict)"; then
    log_error "${conflict} is installed. Webmin manages the web stack itself — remove it first."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl
  local script="/tmp/webmin-setup-repo.sh"
  si_download_locked webmin-setup "${script}"
  sh "${script}" --force

  case "${SI_PKG_MANAGER}" in
    apt|dnf|yum) si_pkg_install webmin ;;
    *)
      log_error "Unsupported package manager: ${SI_PKG_MANAGER}"
      return 1
      ;;
  esac

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable webmin >/dev/null 2>&1 || true
    systemctl restart webmin >/dev/null 2>&1 || systemctl start webmin >/dev/null 2>&1 || true
  fi
}

module_verify() { module_check; }
