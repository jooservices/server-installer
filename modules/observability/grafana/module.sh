#!/usr/bin/env bash
# Grafana OSS (official package repo).

MODULE_ID="grafana"
MODULE_TITLE="Grafana"

module_check() {
  command -v grafana-server >/dev/null 2>&1 || command -v grafana >/dev/null 2>&1
}

module_plan() {
  if module_check; then
    log_plan "Grafana already installed"
  else
    log_plan "Will install Grafana OSS from apt.grafana.com / rpm.grafana.com"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install apt-transport-https software-properties-common wget gnupg
      mkdir -p /etc/apt/keyrings
      if [[ ! -f /etc/apt/keyrings/grafana.gpg ]]; then
        wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
      fi
      echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
        >/etc/apt/sources.list.d/grafana.list
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq grafana
      ;;
    redhat)
      cat >/etc/yum.repos.d/grafana.repo <<'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
EOF
      dnf install -y -q grafana
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable grafana-server >/dev/null 2>&1 || true
    systemctl restart grafana-server >/dev/null 2>&1 || systemctl start grafana-server >/dev/null 2>&1 || true
  fi
}

module_verify() {
  module_check
}
