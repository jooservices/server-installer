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
    *)
      return 1
      ;;
  esac
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
    *)
      log_error "Unsupported package manager: ${SI_PKG_MANAGER}"
      return 1
      ;;
  esac
}
