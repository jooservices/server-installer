#!/usr/bin/env bash
# Download helpers for externally fetched artifacts.

SI_DOWNLOAD_LOCK_FILE="${SI_DOWNLOAD_LOCK_FILE:-${SI_ROOT}/metadata/downloads.json}"

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
  if [[ "${SI_DRY_RUN:-false}" == "true" ]]; then
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

si_sha256() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${file}" | awk '{print $1}'
  else
    shasum -a 256 "${file}" | awk '{print $1}'
  fi
}

si_download() {
  local url="$1"
  local dest="$2"
  local expected_sha256="$3"
  local actual_sha256 part

  if [[ ! "${expected_sha256}" =~ ^[a-fA-F0-9]{64}$ ]]; then
    log_error "A 64-character SHA-256 is required for ${url}"
    return 1
  fi

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    log_plan "Would download and verify ${url} -> ${dest}"
    return 0
  fi

  if ! part="$(mktemp "${dest}.part.XXXXXX")"; then
    log_error "Unable to create a temporary download file for ${dest}"
    return 1
  fi
  if ! curl --fail --location --silent --show-error --output "${part}" "${url}"; then
    rm -f "${part}"
    return 1
  fi

  actual_sha256="$(si_sha256 "${part}")"
  expected_sha256="$(printf '%s' "${expected_sha256}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
    log_error "SHA-256 mismatch for ${url}"
    rm -f "${part}"
    return 1
  fi

  mv "${part}" "${dest}"
}

# Usage: si_download_locked <artifact-id> <destination>
# Every executable artifact is pinned to an exact URL and SHA-256 in the
# repository-owned lockfile. Version overrides without a matching lock entry
# deliberately fail closed.
si_download_locked() {
  local artifact_id="$1"
  local dest="$2"
  local entry url expected_sha256

  if [[ ! -f "${SI_DOWNLOAD_LOCK_FILE}" ]]; then
    log_error "Download lockfile not found: ${SI_DOWNLOAD_LOCK_FILE}"
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    log_error "python3 is required to read the download lockfile"
    return 1
  fi

  entry="$(SI_DL_LOCK_FILE="${SI_DOWNLOAD_LOCK_FILE}" SI_DL_ARTIFACT_ID="${artifact_id}" python3 -c '
import json
import os
import sys

try:
    with open(os.environ["SI_DL_LOCK_FILE"], encoding="utf-8") as handle:
        artifact = json.load(handle)["artifacts"][os.environ["SI_DL_ARTIFACT_ID"]]
    url = artifact["url"]
    checksum = artifact["sha256"]
except (OSError, KeyError, TypeError, ValueError):
    sys.exit(1)

print(f"{url}\t{checksum}")
')" || {
    log_error "No valid locked artifact named ${artifact_id}"
    return 1
  }

  IFS=$'\t' read -r url expected_sha256 <<<"${entry}"
  si_download "${url}" "${dest}" "${expected_sha256}"
}
