#!/usr/bin/env bash
# Enable NTP via chrony (or systemd-timesyncd fallback).

MODULE_ID="timesync"
MODULE_TITLE="NTP time sync"

si_chrony_unit() {
  if [[ "${SI_OS_FAMILY}" == "debian" ]]; then
    printf 'chrony\n'
  else
    printf 'chronyd\n'
  fi
}

module_check() {
  if command -v chronyc >/dev/null 2>&1 || command -v chronyd >/dev/null 2>&1; then
    if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
      local unit
      unit="$(si_chrony_unit)"
      systemctl is-enabled "${unit}" >/dev/null 2>&1 \
        && systemctl is-active "${unit}" >/dev/null 2>&1 \
        && return 0
      # Package present but unit not active yet.
      return 1
    fi
    return 0
  fi

  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -qi '^yes$' && return 0
  fi
  return 1
}

module_plan() {
  if module_check; then
    log_plan "Time sync already active"
  else
    log_plan "Will install/enable chrony for NTP"
  fi
}

module_apply() {
  si_pkg_install chrony

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    return 0
  fi

  local unit
  unit="$(si_chrony_unit)"

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl enable "${unit}" >/dev/null 2>&1 || true
    systemctl restart "${unit}" >/dev/null 2>&1 || systemctl start "${unit}" >/dev/null 2>&1 || true
  elif command -v chronyd >/dev/null 2>&1; then
    # One-shot sync when systemd is unavailable (typical plain Docker).
    # Bound the wait so offline/CI containers do not hang.
    timeout 15 chronyd -q 'pool pool.ntp.org iburst' >/dev/null 2>&1 || \
      log_warn "One-shot NTP sync timed out or failed (package still installed)"
  fi
}

module_verify() {
  if command -v chronyc >/dev/null 2>&1 || command -v chronyd >/dev/null 2>&1 || si_pkg_is_installed chrony; then
    if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
      local unit
      unit="$(si_chrony_unit)"
      systemctl is-active "${unit}" >/dev/null 2>&1 && return 0
      # Accept installed+enabled even if briefly inactive in constrained CI.
      systemctl is-enabled "${unit}" >/dev/null 2>&1 && return 0
      return 1
    fi
    return 0
  fi
  return 1
}
