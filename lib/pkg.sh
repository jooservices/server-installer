#!/usr/bin/env bash
# Package helpers (idempotent install).

si_pkg_is_installed() {
  local pkg="$1"
  case "${SI_PKG_MANAGER}" in
    apt)
      dpkg -s "${pkg}" >/dev/null 2>&1
      ;;
    dnf|yum)
      rpm -q "${pkg}" >/dev/null 2>&1
      ;;
    brew)
      command -v brew >/dev/null 2>&1 && brew list --formula "${pkg}" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

# Homebrew refuses to run as root — never prefix brew calls with sudo.
si_brew_require() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_error "Homebrew refuses to run as root. Re-run this module without sudo."
    return 1
  fi
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not installed. Apply module homebrew first."
    return 1
  fi
  return 0
}

# True when `brew services` reports the formula's service as running.
# Queries the formula directly (accepts bare or fully-qualified tap/formula
# names) via `brew services info --json` rather than matching against
# `brew services list`'s Name column — some taps (e.g. shivammathur/php)
# register the launchd service under a different name than the formula
# itself (php@8.5 installs a service literally named "php").
si_brew_service_running() {
  local name="$1"
  brew services info "${name}" --json 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    sys.exit(0 if data and data[0].get("running") else 1)
except Exception:
    sys.exit(1)
'
}

# Start a formula's service and confirm it — status can lag a moment
# behind launchd actually registering the service, so poll briefly
# instead of checking once immediately after `start` returns.
si_brew_service_start() {
  local name="$1"
  brew services start "${name}" || return 1
  local i
  for i in 1 2 3 4 5; do
    si_brew_service_running "${name}" && return 0
    sleep 1
  done
  return 1
}

si_pkg_install() {
  local pkgs=("$@")
  local missing=()
  local pkg

  for pkg in "${pkgs[@]}"; do
    if ! si_pkg_is_installed "${pkg}"; then
      missing+=("${pkg}")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "${SI_DRY_RUN:-false}" == "true" ]]; then
    log_plan "Would install packages: ${missing[*]}"
    return 0
  fi

  case "${SI_PKG_MANAGER}" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq "${missing[@]}"
      ;;
    dnf)
      dnf install -y -q "${missing[@]}"
      ;;
    yum)
      yum install -y -q "${missing[@]}"
      ;;
    brew)
      si_brew_require || return 1
      brew install "${missing[@]}"
      ;;
    *)
      log_error "Unsupported package manager: ${SI_PKG_MANAGER}"
      return 1
      ;;
  esac
}
