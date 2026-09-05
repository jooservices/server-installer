#!/usr/bin/env bash
# Install Cinc Client (open-source Chef-compatible). Install-only.

MODULE_ID="chef"
MODULE_TITLE="Chef (Cinc Client)"

module_check() {
  command -v cinc-client >/dev/null 2>&1 || command -v chef-client >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Chef/Cinc already installed"; else log_plan "Will install Cinc Client"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl ca-certificates
  curl -fsSL https://omnitruck.cinc.sh/install.sh -o /tmp/cinc-install.sh
  sh /tmp/cinc-install.sh -s -- -P cinc
}

module_verify() { module_check; }
