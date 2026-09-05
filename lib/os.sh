#!/usr/bin/env bash
# OS / package-manager detection.

SI_OS_ID="unknown"
SI_OS_VERSION="unknown"
SI_OS_CODENAME="unknown"
SI_OS_FAMILY="unknown"
SI_PKG_MANAGER="unknown"
SI_CPU_ARCH="unknown"
SI_SYSTEMD_ACTIVE="false"
SI_LVM_AVAILABLE="false"

si_detect_os() {
  SI_CPU_ARCH="$(uname -m 2>/dev/null || echo unknown)"
  case "${SI_CPU_ARCH}" in
    x86_64) SI_CPU_ARCH="amd64" ;;
    aarch64|arm64) SI_CPU_ARCH="arm64" ;;
  esac

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    SI_OS_ID="${ID:-unknown}"
    SI_OS_VERSION="${VERSION_ID:-unknown}"
    SI_OS_CODENAME="${VERSION_CODENAME:-unknown}"
  fi

  case "${SI_OS_ID}" in
    ubuntu|debian|linuxmint|pop)
      SI_OS_FAMILY="debian"
      SI_PKG_MANAGER="apt"
      ;;
    rhel|centos|rocky|almalinux|fedora)
      SI_OS_FAMILY="redhat"
      if command -v dnf >/dev/null 2>&1; then
        SI_PKG_MANAGER="dnf"
      else
        SI_PKG_MANAGER="yum"
      fi
      ;;
    *)
      SI_OS_FAMILY="unknown"
      if command -v apt-get >/dev/null 2>&1; then
        SI_PKG_MANAGER="apt"
        SI_OS_FAMILY="debian"
      elif command -v dnf >/dev/null 2>&1; then
        SI_PKG_MANAGER="dnf"
        SI_OS_FAMILY="redhat"
      fi
      ;;
  esac

  if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    SI_SYSTEMD_ACTIVE="true"
  elif [[ -d /run/systemd/system ]]; then
    SI_SYSTEMD_ACTIVE="true"
  else
    SI_SYSTEMD_ACTIVE="false"
  fi

  if command -v vgs >/dev/null 2>&1 && vgs >/dev/null 2>&1; then
    SI_LVM_AVAILABLE="true"
  elif command -v lvs >/dev/null 2>&1; then
    SI_LVM_AVAILABLE="true"
  else
    SI_LVM_AVAILABLE="false"
  fi
}
