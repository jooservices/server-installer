#!/usr/bin/env bash
# Install Ansible (ansible-core). Install-only — not the provisioner engine.

MODULE_ID="ansible"
MODULE_TITLE="Ansible"

module_check() {
  command -v ansible >/dev/null 2>&1 && command -v ansible-playbook >/dev/null 2>&1
}

module_plan() {
  if module_check; then
    log_plan "Ansible already installed"
  else
    log_plan "Will install ansible-core (CLI only; playbooks call server-installer)"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install ansible-core || si_pkg_install ansible
      ;;
    redhat)
      si_pkg_install epel-release
      si_pkg_install ansible-core || si_pkg_install ansible
      ;;
    *)
      log_error "Unsupported OS"
      return 1
      ;;
  esac
}

module_verify() { module_check; }
