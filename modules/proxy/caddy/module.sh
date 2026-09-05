#!/usr/bin/env bash
# Caddy web server / reverse proxy (official repo).

MODULE_ID="caddy"
MODULE_TITLE="Caddy"

module_check() {
  command -v caddy >/dev/null 2>&1
}

module_plan() {
  if command -v haproxy >/dev/null 2>&1 && [[ "${SI_FORCE_BOTH_PROXIES:-false}" != "true" ]]; then
    log_plan "HAProxy detected — set SI_FORCE_BOTH_PROXIES=true to install caddy anyway"
  fi
  if module_check; then log_plan "Caddy already installed"; else log_plan "Will install caddy"; fi
}

module_apply() {
  if command -v haproxy >/dev/null 2>&1 && [[ "${SI_FORCE_BOTH_PROXIES:-false}" != "true" ]]; then
    log_error "HAProxy is installed. Uninstall or set SI_FORCE_BOTH_PROXIES=true"
    return 1
  fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if module_check; then return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install debian-keyring debian-archive-keyring apt-transport-https curl
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        >/etc/apt/sources.list.d/caddy-stable.list
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq caddy
      ;;
    redhat)
      dnf install -y -q 'dnf-command(copr)'
      dnf copr enable -y @caddy/caddy
      dnf install -y -q caddy
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl enable caddy >/dev/null 2>&1 || true
    systemctl restart caddy >/dev/null 2>&1 || true
  fi
}

module_verify() { command -v caddy >/dev/null 2>&1; }
