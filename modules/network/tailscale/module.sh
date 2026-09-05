#!/usr/bin/env bash
# Tailscale VPN client (official install script).

MODULE_ID="tailscale"
MODULE_TITLE="Tailscale"

module_check() {
  command -v tailscale >/dev/null 2>&1 && command -v tailscaled >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Tailscale already installed"; else log_plan "Will install Tailscale (auth via SI_TAILSCALE_AUTHKEY later)"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  si_pkg_install curl
  curl -fsSL https://tailscale.com/install.sh | sh
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable --now tailscaled >/dev/null 2>&1 || true
  fi
  if [[ -n "${SI_TAILSCALE_AUTHKEY:-}" ]]; then
    tailscale up --auth-key="${SI_TAILSCALE_AUTHKEY}" --accept-routes >/dev/null 2>&1 || true
  fi
}

module_verify() { command -v tailscale >/dev/null 2>&1; }
