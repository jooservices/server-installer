#!/usr/bin/env bash
# WireGuard VPN tools + enable module.

MODULE_ID="wireguard"
MODULE_TITLE="WireGuard"

module_check() {
  command -v wg >/dev/null 2>&1 && command -v wg-quick >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "WireGuard tools present"; else log_plan "Will install wireguard tools"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if module_check; then return 0; fi
  case "${SI_OS_FAMILY}" in
    debian) si_pkg_install wireguard wireguard-tools ;;
    redhat)
      si_pkg_install epel-release
      si_pkg_install wireguard-tools
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
  modprobe wireguard 2>/dev/null || true
}

module_verify() { command -v wg >/dev/null 2>&1; }
