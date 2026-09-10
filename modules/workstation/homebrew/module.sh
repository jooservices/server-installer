#!/usr/bin/env bash
# Homebrew (official install script). macOS only — prerequisite for every
# other brew-backed module (php, redis, mariadb, mongodb on macOS).
# Homebrew refuses to run as root; never invoke this under sudo.

MODULE_ID="homebrew"
MODULE_TITLE="Homebrew"

si_brew_prefix() {
  case "${SI_CPU_ARCH}" in
    arm64) printf '/opt/homebrew\n' ;;
    *) printf '/usr/local\n' ;;
  esac
}

module_check() {
  command -v brew >/dev/null 2>&1 || [[ -x "$(si_brew_prefix)/bin/brew" ]]
}

module_plan() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_plan "Running as root — Homebrew will refuse; re-run without sudo"
  fi
  if module_check; then
    log_plan "Homebrew already installed"
  else
    log_plan "Will install Homebrew via official install script"
  fi
}

module_apply() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_error "Homebrew refuses to run as root. Re-run this module without sudo."
    return 1
  fi

  local prefix brew_bin
  prefix="$(si_brew_prefix)"
  brew_bin="${prefix}/bin/brew"

  if module_check; then
    eval "$("${brew_bin}" shellenv)"
    return 0
  fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local script="${TMPDIR:-/tmp}/homebrew-install.sh"
  si_download_locked homebrew-install "${script}"
  NONINTERACTIVE=1 /bin/bash "${script}"
  rm -f "${script}"
  eval "$("${brew_bin}" shellenv)"

  local profile="${HOME}/.zprofile"
  if ! grep -qF "${brew_bin} shellenv" "${profile}" 2>/dev/null; then
    printf '\neval "$(%s shellenv)"\n' "${brew_bin}" >>"${profile}"
  fi
}

module_verify() { module_check; }
