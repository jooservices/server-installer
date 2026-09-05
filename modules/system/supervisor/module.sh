#!/usr/bin/env bash
# Install Supervisor process manager.

MODULE_ID="supervisor"
MODULE_TITLE="Supervisor"

module_check() {
  command -v supervisord >/dev/null 2>&1 && command -v supervisorctl >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Supervisor already installed"; else log_plan "Will install supervisor"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install supervisor
      mkdir -p /etc/supervisor/conf.d
      ;;
    redhat)
      si_pkg_install epel-release
      si_pkg_install supervisor
      mkdir -p /etc/supervisord.d
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac

  local unit="supervisor"
  [[ "${SI_OS_FAMILY}" == "redhat" ]] && unit="supervisord"
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable "${unit}" >/dev/null 2>&1 || true
    systemctl restart "${unit}" >/dev/null 2>&1 || systemctl start "${unit}" >/dev/null 2>&1 || true
  fi
}

module_verify() { module_check; }
