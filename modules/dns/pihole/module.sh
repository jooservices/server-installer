#!/usr/bin/env bash
# Pi-hole DNS filter. Prefers Docker when available (reliable); else official installer.
# Mutex with adguard.

MODULE_ID="pihole"
MODULE_TITLE="Pi-hole"

module_check() {
  if command -v docker >/dev/null 2>&1 && si_docker_container_exists pihole; then
    return 0
  fi
  command -v pihole >/dev/null 2>&1 || [[ -d /etc/pihole && -f /usr/local/bin/pihole ]]
}

module_plan() {
  if [[ -x /opt/AdGuardHome/AdGuardHome ]] || command -v AdGuardHome >/dev/null 2>&1; then
    log_plan "AdGuard Home detected — pihole will refuse (mutex)"
  fi
  if module_check; then
    log_plan "Pi-hole already installed"
  elif command -v docker >/dev/null 2>&1; then
    log_plan "Will run pihole/pihole Docker image"
  else
    log_plan "Will run official Pi-hole installer (unattended)"
  fi
}

module_apply() {
  if [[ -x /opt/AdGuardHome/AdGuardHome ]] || command -v AdGuardHome >/dev/null 2>&1; then
    log_error "AdGuard Home is installed. Remove it before installing Pi-hole."
    return 1
  fi
  if module_check; then
    return 0
  fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  # Prefer Docker — works in CI/containers and typical docker hosts.
  if command -v docker >/dev/null 2>&1; then
    if ! docker info >/dev/null 2>&1; then
      if command -v dockerd >/dev/null 2>&1; then
        dockerd >/var/log/dockerd.log 2>&1 &
        for _ in $(seq 1 30); do
          docker info >/dev/null 2>&1 && break
          sleep 1
        done
      fi
    fi
        if docker info >/dev/null 2>&1; then
      local pw
      pw="${SI_PIHOLE_PASSWORD:-}"
      if [[ -z "${pw}" ]]; then
        pw="$(python3 -c 'import secrets; print(secrets.token_urlsafe(12))')"
        log_warn "Generated Pi-hole web password: ${pw}"
      fi
      # Avoid host network DNS :53 conflicts in nested E2E when needed.
      docker run -d \
        --name pihole \
        --restart=unless-stopped \
        -e "TZ=${SI_TZ:-UTC}" \
        -e "FTLCONF_webserver_api_password=${pw}" \
        -e "FTLCONF_dns_listeningMode=all" \
        -p "${SI_PIHOLE_DNS_PORT:-5353}:53/tcp" \
        -p "${SI_PIHOLE_DNS_PORT:-5353}:53/udp" \
        -p "${SI_PIHOLE_WEB_PORT:-8088}:80/tcp" \
        -v pihole_etc:/etc/pihole \
        -v pihole_dnsmasq:/etc/dnsmasq.d \
        pihole/pihole:latest
      return 0
    fi
  fi

  si_pkg_install curl
  mkdir -p /etc/pihole
  if [[ ! -f /etc/pihole/setupVars.conf ]]; then
    cat >/etc/pihole/setupVars.conf <<EOF
PIHOLE_INTERFACE=${SI_PIHOLE_INTERFACE:-eth0}
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=local
BLOCKING_ENABLED=true
PIHOLE_DNS_1=1.1.1.1
PIHOLE_DNS_2=8.8.8.8
EOF
  fi
  export PIHOLE_SKIP_OS_CHECK="${PIHOLE_SKIP_OS_CHECK:-true}"
  # nosemgrep: bash.curl.security.curl-pipe-bash.curl-pipe-bash -- upstream Pi-hole installer
  curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
}

module_verify() {
  module_check
}
