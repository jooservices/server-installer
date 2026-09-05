#!/usr/bin/env bash
# Exclusive run lock.

SI_LOCK_FD=""
SI_LOCK_FILE="${SI_LOCK_FILE:-/tmp/server-installer.lock}"

si_acquire_lock() {
  if [[ "${SI_SKIP_LOCK:-false}" == "true" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "${SI_LOCK_FILE}")"
  exec {SI_LOCK_FD}>"${SI_LOCK_FILE}"
  if ! flock -n "${SI_LOCK_FD}"; then
    log_error "Another server-installer process is running (lock: ${SI_LOCK_FILE})."
    exit 1
  fi
}
