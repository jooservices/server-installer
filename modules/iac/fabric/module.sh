#!/usr/bin/env bash
# Install Fabric CLI (pip). Install-only.

MODULE_ID="fabric"
MODULE_TITLE="Fabric"

module_check() {
  command -v fab >/dev/null 2>&1 || command -v fabric >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Fabric already installed"; else log_plan "Will pip-install fabric"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install python3 python3-pip
  if command -v pipx >/dev/null 2>&1; then
    pipx install fabric
  else
    python3 -m pip install --break-system-packages -q fabric
  fi
}

module_verify() { module_check; }
