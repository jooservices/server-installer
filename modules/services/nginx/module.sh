#!/usr/bin/env bash
# Nginx web server. Independent of PHP (compose via --modules).

MODULE_ID="nginx"
MODULE_TITLE="Nginx"

module_check() {
  command -v nginx >/dev/null 2>&1
}

module_plan() {
  if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
    if [[ "${SI_FORCE_BOTH_WEBSERVERS:-false}" != "true" ]]; then
      log_plan "Apache detected — nginx will refuse unless SI_FORCE_BOTH_WEBSERVERS=true"
    else
      log_plan "Apache detected but SI_FORCE_BOTH_WEBSERVERS=true"
    fi
  fi
  if module_check; then
    log_plan "Nginx already installed"
  else
    log_plan "Will install nginx via ${SI_PKG_MANAGER}"
  fi
}

module_apply() {
  if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
    if [[ "${SI_FORCE_BOTH_WEBSERVERS:-false}" != "true" ]]; then
      log_error "Apache is installed. Uninstall it or set SI_FORCE_BOTH_WEBSERVERS=true"
      return 1
    fi
  fi

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  if ! module_check; then
    si_pkg_install nginx
  fi

  # Harden default: hide version token when config exists.
  if [[ -f /etc/nginx/nginx.conf ]] && ! grep -q "server_tokens off;" /etc/nginx/nginx.conf; then
    sed -i '/http {/a\    server_tokens off;' /etc/nginx/nginx.conf || true
  fi

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    if nginx -t >/dev/null 2>&1; then
      systemctl enable nginx >/dev/null 2>&1 || true
      systemctl restart nginx >/dev/null 2>&1 || systemctl start nginx >/dev/null 2>&1 || true
    else
      log_error "nginx -t failed"
      return 1
    fi
  elif command -v nginx >/dev/null 2>&1; then
    nginx -t >/dev/null 2>&1 || return 1
    nginx >/dev/null 2>&1 || nginx -s reload >/dev/null 2>&1 || true
  fi
}

module_verify() {
  command -v nginx >/dev/null 2>&1 || return 1
  nginx -t >/dev/null 2>&1
}
