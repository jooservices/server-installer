#!/usr/bin/env bash
# HashiCorp Vault (official apt/yum or binary). Dev-mode not enabled by default.

MODULE_ID="vault"
MODULE_TITLE="Vault"

module_check() {
  command -v vault >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Vault already installed"; else log_plan "Will install Vault from HashiCorp repo"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install wget gpg
      wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${SI_OS_CODENAME} main" \
        >/etc/apt/sources.list.d/hashicorp.list
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq vault
      ;;
    redhat)
      si_pkg_install yum-utils
      yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      dnf install -y -q vault
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { command -v vault >/dev/null 2>&1; }
