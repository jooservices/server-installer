#!/usr/bin/env bash
# Passwordless sudo for a non-root admin user.

MODULE_ID="sudo_nopass"
MODULE_TITLE="Passwordless sudo"

si_sudo_target_user() {
  if [[ -n "${SI_SUDO_USER:-}" ]]; then
    printf '%s\n' "${SI_SUDO_USER}"
    return 0
  fi
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "${SUDO_USER}"
    return 0
  fi
  if [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
    printf '%s\n' "${USER}"
    return 0
  fi
  local login
  login="$(logname 2>/dev/null || true)"
  if [[ -n "${login}" && "${login}" != "root" ]]; then
    printf '%s\n' "${login}"
    return 0
  fi
  printf '\n'
}

si_sudoers_file_for() {
  local user="$1"
  # Must sort after typical drop-ins like "deploy" so NOPASSWD wins.
  printf '/etc/sudoers.d/z99-%s-nopasswd\n' "${user}"
}

module_check() {
  local user file
  user="$(si_sudo_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    # Nothing to configure for root-only environments.
    return 0
  fi
  file="$(si_sudoers_file_for "${user}")"
  [[ -f "${file}" ]] && grep -q "NOPASSWD:ALL" "${file}"
}

module_plan() {
  local user
  user="$(si_sudo_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    log_plan "No non-root target user; sudo_nopass will no-op"
    return 0
  fi
  if module_check; then
    log_plan "Passwordless sudo already configured for ${user}"
  else
    log_plan "Will write $(si_sudoers_file_for "${user}") for ${user}"
  fi
}

module_apply() {
  local user file temp
  user="$(si_sudo_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    log_skip "No non-root user to grant passwordless sudo"
    return 0
  fi

  if ! id "${user}" >/dev/null 2>&1; then
    log_error "User ${user} does not exist"
    return 1
  fi

  file="$(si_sudoers_file_for "${user}")"
  temp="$(mktemp)"

  printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${user}" >"${temp}"
  chmod 0440 "${temp}"

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    log_plan "Would install sudoers drop-in ${file}"
    rm -f "${temp}"
    return 0
  fi

  if command -v visudo >/dev/null 2>&1; then
    if ! visudo -c -f "${temp}" >/dev/null 2>&1; then
      log_error "visudo rejected sudoers fragment"
      rm -f "${temp}"
      return 1
    fi
  fi

  mkdir -p /etc/sudoers.d
  mv "${temp}" "${file}"
  chown root:root "${file}" 2>/dev/null || true
  chmod 0440 "${file}"
}

module_verify() {
  local user
  user="$(si_sudo_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    return 0
  fi
  if ! module_check; then
    return 1
  fi
  if command -v sudo >/dev/null 2>&1; then
    if su -s /bin/bash -c "sudo -n true" "${user}" >/dev/null 2>&1; then
      return 0
    fi
    log_error "sudoers file present but sudo -n failed for ${user} (check drop-in order)"
    return 1
  fi
  return 0
}
