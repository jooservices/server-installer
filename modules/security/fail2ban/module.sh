#!/usr/bin/env bash
# fail2ban with SSH jail defaults.

MODULE_ID="fail2ban"
MODULE_TITLE="fail2ban"

module_check() {
  command -v fail2ban-client >/dev/null 2>&1 \
    && [[ -f /etc/fail2ban/jail.local ]]
}

module_plan() {
  if module_check; then
    log_plan "fail2ban already configured"
  else
    log_plan "Will install fail2ban and write jail.local (SSH)"
  fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  case "${SI_OS_FAMILY}" in
    debian) si_pkg_install fail2ban ;;
    redhat)
      si_pkg_install epel-release
      si_pkg_install fail2ban
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac

  mkdir -p /etc/fail2ban
  cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
EOF

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable fail2ban >/dev/null 2>&1 || true
    systemctl restart fail2ban >/dev/null 2>&1 || systemctl start fail2ban >/dev/null 2>&1 || true
  fi
}

module_verify() {
  command -v fail2ban-client >/dev/null 2>&1 && [[ -f /etc/fail2ban/jail.local ]]
}
