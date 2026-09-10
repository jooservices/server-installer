#!/usr/bin/env bash
# Install Pulumi CLI. Install-only.

MODULE_ID="pulumi"
MODULE_TITLE="Pulumi"

SI_PULUMI_VERSION="${SI_PULUMI_VERSION:-3.261.0}"

module_check() {
  command -v pulumi >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Pulumi already installed"; else log_plan "Will install Pulumi CLI v${SI_PULUMI_VERSION}"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl ca-certificates tar
  local arch tar extract
  arch="$(si_arch_suffix)"
  tar="/tmp/pulumi.tar.gz"
  extract="/tmp/pulumi_extracted"
  si_download_locked "pulumi-${SI_PULUMI_VERSION}-linux-${arch}" "${tar}"
  rm -rf "${extract}"
  mkdir -p "${extract}"
  tar -xzf "${tar}" -C "${extract}"
  install -m 0755 "${extract}/pulumi/pulumi" /usr/local/bin/pulumi
  rm -rf "${tar}" "${extract}"
}

module_verify() { command -v pulumi >/dev/null 2>&1; }
