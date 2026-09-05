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
  curl -fsSL https://sentry.io/get-cli/ | sh
  if [[ -x /usr/local/bin/sentry-cli ]]; then
    return 0
  fi
  # Fallback: GitHub release binary
  local arch ver
  arch="$(si_arch_suffix)"
  [[ "${arch}" == "amd64" ]] && arch="x86_64" || arch="aarch64"
  ver="${SI_SENTRY_CLI_VERSION:-2.39.1}"
  curl -fsSL \
    "https://github.com/getsentry/sentry-cli/releases/download/${ver}/sentry-cli-Linux-${arch}" \
    -o /usr/local/bin/sentry-cli
  chmod +x /usr/local/bin/sentry-cli
}

module_verify() { command -v sentry-cli >/dev/null 2>&1; }
