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

# True when `brew services` reports the formula's service as started.
# Accepts a bare formula or a fully-qualified tap/formula name — `brew
# services list` always shows the short name in its Name column.
si_brew_service_running() {
  local name="${1##*/}"
  brew services list 2>/dev/null | grep -qE "^${name}[[:space:]]+started"
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
