#!/usr/bin/env bash
# Certbot (Let's Encrypt client).

MODULE_ID="certbot"
MODULE_TITLE="Certbot"

module_check() {
  command -v certbot >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "certbot already installed"; else log_plan "Will install certbot (+ nginx/apache plugin if those exist)"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if module_check; then return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      local pkgs=(certbot)
      command -v nginx >/dev/null 2>&1 && pkgs+=(python3-certbot-nginx)
      command -v apache2 >/dev/null 2>&1 && pkgs+=(python3-certbot-apache)
      si_pkg_install "${pkgs[@]}"
      ;;
    redhat)
      si_pkg_install epel-release
      si_pkg_install certbot
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { command -v certbot >/dev/null 2>&1; }
