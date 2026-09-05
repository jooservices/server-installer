#!/usr/bin/env bash
# Full package upgrade (apt/dnf). Always applies when selected.

MODULE_ID="upgrade"
MODULE_TITLE="System upgrade"

module_check() {
  # Non-idempotent by nature — never skip apply when selected.
  return 1
}

module_plan() {
  log_plan "Will update indexes and upgrade all packages"
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_PKG_MANAGER}" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get upgrade -y -qq
      ;;
    dnf)
      dnf upgrade -y -q
      ;;
    yum)
      yum update -y -q
      ;;
    *)
      log_error "Unsupported package manager: ${SI_PKG_MANAGER}"
      return 1
      ;;
  esac

  mkdir -p /var/lib/server-installer
  date -u +%Y-%m-%dT%H:%M:%SZ >/var/lib/server-installer/last-upgrade

  if [[ -f /var/run/reboot-required ]]; then
    log_warn "Reboot recommended (/var/run/reboot-required)"
  fi
}

module_verify() {
  [[ -f /var/lib/server-installer/last-upgrade ]]
}
