#!/usr/bin/env bash
# Install Pulumi CLI. Install-only.

MODULE_ID="pulumi"
MODULE_TITLE="Pulumi"

module_check() {
  command -v pulumi >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Pulumi already installed"; else log_plan "Will install Pulumi CLI"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl ca-certificates tar
  curl -fsSL https://get.pulumi.com | sh
  if [[ -x "${HOME}/.pulumi/bin/pulumi" ]]; then
    ln -sf "${HOME}/.pulumi/bin/pulumi" /usr/local/bin/pulumi
  elif [[ -x /root/.pulumi/bin/pulumi ]]; then
    ln -sf /root/.pulumi/bin/pulumi /usr/local/bin/pulumi
  fi
}

module_verify() { command -v pulumi >/dev/null 2>&1; }
