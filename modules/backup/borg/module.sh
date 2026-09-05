#!/usr/bin/env bash
# BorgBackup.

MODULE_ID="borg"
MODULE_TITLE="BorgBackup"

module_check() {
  command -v borg >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "borg already installed"; else log_plan "Will install borgbackup"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if module_check; then return 0; fi
  case "${SI_OS_FAMILY}" in
    debian) si_pkg_install borgbackup ;;
    redhat)
      si_pkg_install epel-release
      si_pkg_install borgbackup
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { command -v borg >/dev/null 2>&1; }
