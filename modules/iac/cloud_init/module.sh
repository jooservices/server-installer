#!/usr/bin/env bash
# Install cloud-init package (install-only; does not reconfigure cloud).

MODULE_ID="cloud_init"
MODULE_TITLE="cloud-init"

module_check() {
  command -v cloud-init >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "cloud-init already installed"; else log_plan "Will install cloud-init package"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian) si_pkg_install cloud-init ;;
    redhat) si_pkg_install cloud-init ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { command -v cloud-init >/dev/null 2>&1; }
