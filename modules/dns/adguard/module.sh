#!/usr/bin/env bash
# AdGuard Home DNS filter (official install script / binary).
# Mutex with pihole.

MODULE_ID="adguard"
MODULE_TITLE="AdGuard Home"

SI_ADGUARD_VERSION="${SI_ADGUARD_VERSION:-0.107.52}"

module_check() {
  [[ -x /opt/AdGuardHome/AdGuardHome ]] || command -v AdGuardHome >/dev/null 2>&1
}

module_plan() {
  if command -v pihole >/dev/null 2>&1 || [[ -d /etc/pihole ]]; then
    log_plan "Pi-hole detected — adguard will refuse (mutex)"
  fi
  if module_check; then log_plan "AdGuard Home already installed"; else log_plan "Will install AdGuard Home v${SI_ADGUARD_VERSION}"; fi
}

module_apply() {
  if command -v pihole >/dev/null 2>&1 || [[ -d /etc/pihole ]]; then
    log_error "Pi-hole is installed. Remove it before installing AdGuard Home."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local arch url tar
  case "${SI_CPU_ARCH}" in
    arm64) arch="arm64" ;;
    *) arch="amd64" ;;
  esac
  url="https://github.com/AdguardTeam/AdGuardHome/releases/download/v${SI_ADGUARD_VERSION}/AdGuardHome_linux_${arch}.tar.gz"
  tar="/tmp/adguard.tgz"
  si_download "${url}" "${tar}"
  mkdir -p /tmp/adguard_extracted /opt/AdGuardHome
  tar -xzf "${tar}" -C /tmp/adguard_extracted
  cp -a /tmp/adguard_extracted/AdGuardHome/. /opt/AdGuardHome/
  chmod +x /opt/AdGuardHome/AdGuardHome
  rm -rf "${tar}" /tmp/adguard_extracted

  # Non-interactive install as service when systemd available.
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    /opt/AdGuardHome/AdGuardHome -s install >/dev/null 2>&1 || true
    /opt/AdGuardHome/AdGuardHome -s start >/dev/null 2>&1 || true
  fi
}

module_verify() { module_check; }
