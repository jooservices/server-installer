#!/usr/bin/env bash
# Logging helpers for server-installer.

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  COLOR_RESET=$'\033[0m'
  COLOR_BOLD=$'\033[1m'
  COLOR_RED=$'\033[0;31m'
  COLOR_GREEN=$'\033[0;32m'
  COLOR_YELLOW=$'\033[0;33m'
  COLOR_BLUE=$'\033[0;34m'
  COLOR_CYAN=$'\033[0;36m'
else
  COLOR_RESET="" COLOR_BOLD="" COLOR_RED="" COLOR_GREEN=""
  COLOR_YELLOW="" COLOR_BLUE="" COLOR_CYAN=""
fi

log_msg() {
  local level="$1" color="$2" message="$3"
  printf '%b[%s]%b %s\n' "${color}" "${level}" "${COLOR_RESET}" "${message}" >&2
}

log_info()    { log_msg "INFO"    "${COLOR_BLUE}"    "$1"; }
log_success() { log_msg "OK"      "${COLOR_GREEN}"   "$1"; }
log_warn()    { log_msg "WARN"    "${COLOR_YELLOW}"  "$1"; }
log_error()   { log_msg "ERROR"   "${COLOR_RED}"     "$1"; }
log_plan()    { log_msg "PLAN"    "${COLOR_CYAN}"    "$1"; }
log_skip()    { log_msg "SKIP"    "${COLOR_YELLOW}"  "$1"; }
