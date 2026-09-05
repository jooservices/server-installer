#!/usr/bin/env bash
# Install base archive tools: zip + unzip.

MODULE_ID="packages"
MODULE_TITLE="Base packages (zip, unzip)"

SI_PACKAGES_LIST=(zip unzip)

module_check() {
  local pkg
  for pkg in "${SI_PACKAGES_LIST[@]}"; do
    if ! si_pkg_is_installed "${pkg}"; then
      return 1
    fi
    if ! command -v "${pkg}" >/dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

module_plan() {
  local pkg
  for pkg in "${SI_PACKAGES_LIST[@]}"; do
    if si_pkg_is_installed "${pkg}"; then
      log_plan "${pkg}: already installed"
    else
      log_plan "${pkg}: will install via ${SI_PKG_MANAGER}"
    fi
  done
}

module_apply() {
  si_pkg_install "${SI_PACKAGES_LIST[@]}"
}

module_verify() {
  module_check
}
