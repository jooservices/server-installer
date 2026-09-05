#!/usr/bin/env bash
# Install OpenTofu CLI. Install-only.

MODULE_ID="opentofu"
MODULE_TITLE="OpenTofu"

module_check() {
  command -v tofu >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "OpenTofu already installed"; else log_plan "Will install OpenTofu binary"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  si_pkg_install curl ca-certificates unzip
  rm -f /etc/apt/sources.list.d/opentofu.list

  local arch ver tmp
  arch="$(si_arch_suffix)"
  ver="${SI_OPENTOFU_VERSION:-1.12.6}"
  tmp="$(mktemp -d)"
  curl -fsSL \
    "https://github.com/opentofu/opentofu/releases/download/v${ver}/tofu_${ver}_linux_${arch}.zip" \
    -o "${tmp}/tofu.zip"
  unzip -qo "${tmp}/tofu.zip" -d "${tmp}"
  install -m 0755 "${tmp}/tofu" /usr/local/bin/tofu
  rm -rf "${tmp}"
}

module_verify() { command -v tofu >/dev/null 2>&1; }
