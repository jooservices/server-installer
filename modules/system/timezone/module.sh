#!/usr/bin/env bash
# Configure system timezone (SI_TIMEZONE or SI_TZ, default UTC).

MODULE_ID="timezone"
MODULE_TITLE="Timezone"

si_timezone_want() {
  printf '%s\n' "${SI_TIMEZONE:-${SI_TZ:-UTC}}"
}

module_check() {
  local want
  want="$(si_timezone_want)"
  if [[ -f /etc/timezone ]]; then
    [[ "$(tr -d '[:space:]' </etc/timezone)" == "${want}" ]] && return 0
  fi
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl show -p Timezone --value 2>/dev/null | grep -xF "${want}" >/dev/null && return 0
  fi
  [[ "$(readlink -f /etc/localtime 2>/dev/null || true)" == *"/zoneinfo/${want}" ]]
}

module_plan() {
  local want
  want="$(si_timezone_want)"
  if module_check; then log_plan "Timezone already ${want}"; else log_plan "Will set timezone to ${want}"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  local want
  want="$(si_timezone_want)"
  if module_check; then return 0; fi

  if [[ ! -d /usr/share/zoneinfo ]]; then
    si_pkg_install tzdata
  fi

  if command -v timedatectl >/dev/null 2>&1 && [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    timedatectl set-timezone "${want}"
  else
    if [[ ! -f "/usr/share/zoneinfo/${want}" ]]; then
      log_error "Zoneinfo not found: ${want}"
      return 1
    fi
    ln -sf "/usr/share/zoneinfo/${want}" /etc/localtime
    printf '%s\n' "${want}" >/etc/timezone
  fi
}

module_verify() { module_check; }
