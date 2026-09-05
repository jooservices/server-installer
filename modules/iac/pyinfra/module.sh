#!/usr/bin/env bash
# Install PyInfra CLI (pip). Install-only.

MODULE_ID="pyinfra"
MODULE_TITLE="PyInfra"

module_check() {
  command -v pyinfra >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "pyinfra already installed"; else log_plan "Will pip-install pyinfra"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install python3 python3-pip python3-venv
  if command -v pipx >/dev/null 2>&1; then
    pipx install pyinfra
  else
    python3 -m pip install --break-system-packages -q pyinfra
  fi
}

module_verify() { command -v pyinfra >/dev/null 2>&1; }
