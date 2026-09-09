#!/usr/bin/env bash
# Exclusive run lock. Uses mkdir for atomicity — portable to macOS, which
# ships neither flock(1) nor bash 4+ (needed for `exec {fd}>` auto-assignment).

SI_LOCK_FILE="${SI_LOCK_FILE:-/tmp/server-installer.lock}"
SI_LOCK_DIR="${SI_LOCK_FILE}.d"
SI_LOCK_HELD="false"

si_release_lock() {
  [[ "${SI_LOCK_HELD}" == "true" ]] && rm -rf "${SI_LOCK_DIR}"
}

si_acquire_lock() {
  if [[ "${SI_SKIP_LOCK:-false}" == "true" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "${SI_LOCK_FILE}")"

  if ! mkdir "${SI_LOCK_DIR}" 2>/dev/null; then
    local held_pid
    held_pid="$(cat "${SI_LOCK_DIR}/pid" 2>/dev/null || true)"
    if [[ -n "${held_pid}" ]] && kill -0 "${held_pid}" 2>/dev/null; then
      log_error "Another server-installer process is running (pid ${held_pid}, lock: ${SI_LOCK_DIR})."
      exit 1
    fi
    # Holder is gone — stale lock from a killed/crashed run. Reclaim it.
    rm -rf "${SI_LOCK_DIR}"
    if ! mkdir "${SI_LOCK_DIR}" 2>/dev/null; then
      log_error "Another server-installer process is running (lock: ${SI_LOCK_DIR})."
      exit 1
    fi
  fi

  printf '%s\n' "$$" >"${SI_LOCK_DIR}/pid"
  SI_LOCK_HELD="true"
  trap si_release_lock EXIT
}
