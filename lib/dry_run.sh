#!/usr/bin/env bash
# Dry-run aware command execution.

SI_DRY_RUN="${SI_DRY_RUN:-false}"

si_run() {
  local description="$1"
  shift
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    log_plan "${description}: $*"
    return 0
  fi
  log_info "${description}"
  "$@"
}
