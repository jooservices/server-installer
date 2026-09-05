#!/usr/bin/env bash
# Download helpers for GitHub release binaries.

si_arch_suffix() {
  case "${SI_CPU_ARCH}" in
    arm64) printf 'arm64\n' ;;
    *) printf 'amd64\n' ;;
  esac
}

si_ensure_user() {
  local user="$1"
  local group="${2:-$1}"
  if ! getent group "${group}" >/dev/null 2>&1; then
    groupadd --system "${group}"
  fi
  if ! getent passwd "${user}" >/dev/null 2>&1; then
    useradd --system --no-create-home -s /usr/sbin/nologin -g "${group}" "${user}"
  fi
}

si_write_systemd_unit() {
  local name="$1"
  local content="$2"
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    log_plan "Would write /etc/systemd/system/${name}.service"
    return 0
  fi
  printf '%s\n' "${content}" >"/etc/systemd/system/${name}.service"
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl enable "${name}" >/dev/null 2>&1 || true
    systemctl restart "${name}" >/dev/null 2>&1 || systemctl start "${name}" >/dev/null 2>&1 || true
  fi
}

si_download() {
  local url="$1"
  local dest="$2"
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    log_plan "Would download ${url} -> ${dest}"
    return 0
  fi
  curl -fsSL -o "${dest}" "${url}"
}
