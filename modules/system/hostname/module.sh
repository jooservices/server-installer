#!/usr/bin/env bash
# Set system hostname (SI_HOSTNAME).

MODULE_ID="hostname"
MODULE_TITLE="Hostname"

module_check() {
  local want
  want="${SI_HOSTNAME:-}"
  [[ -n "${want}" ]] || return 0
  [[ "$(hostname -f 2>/dev/null || hostname)" == "${want}" ]] \
    || [[ "$(cat /etc/hostname 2>/dev/null || true)" == "${want}" ]]
}

module_plan() {
  local want="${SI_HOSTNAME:-$(hostname 2>/dev/null || echo localhost)}"
  if [[ -z "${SI_HOSTNAME:-}" ]]; then
    log_plan "SI_HOSTNAME unset — will keep current (${want})"
  elif module_check; then
    log_plan "Hostname already ${want}"
  else
    log_plan "Will set hostname to ${want}"
  fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  local want="${SI_HOSTNAME:-}"
  if [[ -z "${want}" ]]; then
    log_skip "SI_HOSTNAME unset — no hostname change"
    return 0
  fi
  if module_check; then return 0; fi

  if command -v hostnamectl >/dev/null 2>&1 && [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    hostnamectl set-hostname "${want}"
  else
    printf '%s\n' "${want}" >/etc/hostname
    hostname "${want}" 2>/dev/null || true
  fi

  if [[ -f /etc/hosts ]]; then
    sed -i.bak '/^127.0.1.1/d' /etc/hosts || true
    printf '127.0.1.1\t%s %s\n' "${want}" "${want%%.*}" >>/etc/hosts
  fi
}

module_verify() {
  local want="${SI_HOSTNAME:-}"
  [[ -z "${want}" ]] && return 0
  module_check
}
