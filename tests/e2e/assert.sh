#!/usr/bin/env bash
# Assert helpers for E2E (run inside container).
set -euo pipefail

assert_cmd() {
  local desc="$1"
  shift
  if "$@"; then
    echo "[PASS] ${desc}"
  else
    echo "[FAIL] ${desc}" >&2
    exit 1
  fi
}

assert_eq() {
  local desc="$1" got="$2" want="$3"
  if [[ "${got}" == "${want}" ]]; then
    echo "[PASS] ${desc}"
  else
    echo "[FAIL] ${desc}: got='${got}' want='${want}'" >&2
    exit 1
  fi
}

# Match an exact line without grep -q (avoids SIGPIPE under pipefail).
assert_line() {
  local desc="$1"
  local want="$2"
  local got
  got="$(cat)"
  if printf '%s\n' "${got}" | grep -xF "${want}" >/dev/null; then
    echo "[PASS] ${desc}"
  else
    echo "[FAIL] ${desc} (want exact line: ${want})" >&2
    exit 1
  fi
}

assert_docker_container() {
  local desc="$1"
  local name="$2"
  local scope="${3:-all}"
  local names
  if [[ "${scope}" == "running" ]]; then
    names="$(docker ps --format '{{.Names}}')"
  else
    names="$(docker ps -a --format '{{.Names}}')"
  fi
  if printf '%s\n' "${names}" | grep -xF "${name}" >/dev/null; then
    echo "[PASS] ${desc}"
  else
    echo "[FAIL] ${desc}" >&2
    exit 1
  fi
}
