#!/usr/bin/env bash
# Install Salt minion (install-only). Optional master: SI_SALT_MASTER=true.

MODULE_ID="salt"
MODULE_TITLE="Salt"

SI_SALT_BOOTSTRAP_VERSION="${SI_SALT_BOOTSTRAP_VERSION:-2026.09.03}"

module_check() {
  command -v salt-call >/dev/null 2>&1 || command -v salt-minion >/dev/null 2>&1
}

module_plan() {
  if module_check; then
    log_plan "Salt already installed"
  else
    log_plan "Will install Salt via official bootstrap (minion$([ "${SI_SALT_MASTER:-false}" = true ] && echo '+master'))"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl ca-certificates
  local script="/tmp/bootstrap-salt.sh"
  si_download_locked "salt-bootstrap-${SI_SALT_BOOTSTRAP_VERSION}" "${script}"
  # Bootstrap may exit non-zero in containers without a real init; packages can still install.
  set +e
  if [[ "${SI_SALT_MASTER:-false}" == "true" ]]; then
    sh "${script}" -M -P stable
  else
    sh "${script}" -P stable
  fi
  set -e
  rm -f "${script}"

  if module_check; then
    return 0
  fi

  # Fallback: install from whatever repo bootstrap configured.
  case "${SI_OS_FAMILY}" in
    debian)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq || true
      apt-get install -y -qq salt-minion || true
      ;;
    redhat)
      dnf install -y -q salt-minion || yum install -y -q salt-minion || true
      ;;
  esac

  if ! module_check; then
    log_error "Salt install failed"
    return 1
  fi
}

module_verify() { module_check; }
