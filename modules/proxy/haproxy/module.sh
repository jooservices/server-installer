#!/usr/bin/env bash
# HAProxy load balancer.

MODULE_ID="haproxy"
MODULE_TITLE="HAProxy"

module_check() {
  command -v haproxy >/dev/null 2>&1
}

module_plan() {
  if command -v caddy >/dev/null 2>&1 && [[ "${SI_FORCE_BOTH_PROXIES:-false}" != "true" ]]; then
    log_plan "Caddy detected — set SI_FORCE_BOTH_PROXIES=true to install haproxy anyway"
  fi
  if module_check; then log_plan "HAProxy already installed"; else log_plan "Will install haproxy"; fi
}

module_apply() {
  if command -v caddy >/dev/null 2>&1 && [[ "${SI_FORCE_BOTH_PROXIES:-false}" != "true" ]]; then
    log_error "Caddy is installed. Uninstall or set SI_FORCE_BOTH_PROXIES=true"
    return 1
  fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if ! module_check; then
    si_pkg_install haproxy
  fi
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable haproxy >/dev/null 2>&1 || true
    systemctl restart haproxy >/dev/null 2>&1 || true
  fi
}

module_verify() { command -v haproxy >/dev/null 2>&1; }
