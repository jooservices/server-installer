#!/usr/bin/env bash
# Install Sentry CLI (upload/release helper). Install-only.

MODULE_ID="sentry_cli"
MODULE_TITLE="Sentry CLI"

module_check() {
  command -v sentry-cli >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "sentry-cli already installed"; else log_plan "Will install sentry-cli"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl ca-certificates
  local arch ver artifact file
  arch="$(si_arch_suffix)"
  ver="${SI_SENTRY_CLI_VERSION:-2.39.1}"
  artifact="sentry-cli-${ver}-linux-${arch}"
  file="/tmp/sentry-cli"
  si_download_locked "${artifact}" "${file}"
  install -m 0755 "${file}" /usr/local/bin/sentry-cli
  rm -f "${file}"
}

module_verify() { command -v sentry-cli >/dev/null 2>&1; }
