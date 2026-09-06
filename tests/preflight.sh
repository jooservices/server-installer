#!/usr/bin/env bash
# Unit checks for preflight verdicts and fail-closed metadata handling.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"
si_bootstrap

assert_verdict() {
  local name="$1" expected="$2" actual
  shift 2
  actual="$1"
  if [[ "${actual%%|*}" != "${expected}" ]]; then
    printf '%s: expected %s, got %s\n' "${name}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

SI_OS_FAMILY=debian
SI_CPU_ARCH=amd64
SI_LVM_AVAILABLE=true
SI_SYSTEMD_ACTIVE=true
assert_verdict "valid metadata passes" PASS "$(si_preflight_check packages)"

SI_SYSTEMD_ACTIVE=false
assert_verdict "systemd requirement blocks" BLOCK "$(si_preflight_check fail2ban)"

SI_SYSTEMD_ACTIVE=true
SI_CPU_ARCH=arm64
assert_verdict "amd64-only metadata warns" WARN "$(si_preflight_check milvus)"

metadata_dir="$(mktemp -d)"
trap 'rm -rf "${metadata_dir}"' EXIT
SI_METADATA_DIR="${metadata_dir}"
printf '{\n' >"${metadata_dir}/broken.json"
assert_verdict "invalid metadata blocks" BLOCK "$(si_preflight_check broken)"
assert_verdict "missing metadata blocks" BLOCK "$(si_preflight_check missing)"

printf 'Preflight tests: OK\n'
