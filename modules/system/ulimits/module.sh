#!/usr/bin/env bash
# Raise ulimits + sysctl defaults for busy servers.

MODULE_ID="ulimits"
MODULE_TITLE="Ulimits / sysctl"

module_check() {
  [[ -f /etc/security/limits.d/99-server-installer.conf ]] \
    && [[ -f /etc/sysctl.d/99-server-installer.conf ]]
}

module_plan() {
  if module_check; then log_plan "Ulimits/sysctl drop-ins present"; else log_plan "Will write limits.d + sysctl.d drop-ins"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if module_check; then return 0; fi

  mkdir -p /etc/security/limits.d /etc/sysctl.d
  cat >/etc/security/limits.d/99-server-installer.conf <<'EOF'
# Managed by server-installer
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF
  cat >/etc/sysctl.d/99-server-installer.conf <<'EOF'
# Managed by server-installer
fs.file-max = 2097152
vm.max_map_count = 262144
vm.swappiness = 10
fs.inotify.max_user_watches = 524288
EOF
  if command -v sysctl >/dev/null 2>&1; then
    sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-server-installer.conf >/dev/null 2>&1 || true
  fi
}

module_verify() { module_check; }
