#!/usr/bin/env bash
# UFW (Debian) or firewalld (RHEL). Keeps SSH open.

MODULE_ID="firewall"
MODULE_TITLE="Firewall"

si_ssh_port() {
  local port=22
  if [[ -f /etc/ssh/sshd_config ]]; then
    port="$(grep -E '^Port [0-9]+' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -n1 || true)"
    [[ -n "${port}" ]] || port=22
  fi
  printf '%s\n' "${port}"
}

module_check() {
  case "${SI_OS_FAMILY}" in
    debian)
      command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -i 'Status: active' >/dev/null
      ;;
    redhat)
      command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1
      ;;
    *) return 1 ;;
  esac
}

module_plan() {
  log_plan "SSH port=$(si_ssh_port); will allow 22/80/443 + SSH"
  if module_check; then
    log_plan "Firewall already active"
  else
    log_plan "Will install/enable ufw or firewalld"
  fi
}

module_apply() {
  local ssh_port
  ssh_port="$(si_ssh_port)"
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install ufw
      ufw default deny incoming >/dev/null
      ufw default allow outgoing >/dev/null
      ufw allow "${ssh_port}/tcp" comment 'SSH' >/dev/null || true
      ufw allow 80/tcp comment 'HTTP' >/dev/null || true
      ufw allow 443/tcp comment 'HTTPS' >/dev/null || true
      echo y | ufw enable >/dev/null
      ;;
    redhat)
      si_pkg_install firewalld
      if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
        systemctl enable --now firewalld >/dev/null 2>&1 || true
      fi
      firewall-cmd --permanent --add-service=ssh >/dev/null 2>&1 || \
        firewall-cmd --permanent --add-port="${ssh_port}/tcp" >/dev/null 2>&1 || true
      firewall-cmd --permanent --add-service=http >/dev/null 2>&1 || true
      firewall-cmd --permanent --add-service=https >/dev/null 2>&1 || true
      firewall-cmd --reload >/dev/null 2>&1 || true
      ;;
    *)
      log_error "Unsupported OS family for firewall"
      return 1
      ;;
  esac
}

module_verify() {
  module_check
}
