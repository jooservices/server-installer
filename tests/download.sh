#!/usr/bin/env bash
# Unit checks for locked and checksummed downloads.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

assert_failure() {
  local name="$1"
  shift
  if "$@"; then
    printf '%s: expected failure\n' "${name}" >&2
    exit 1
  fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
source_file="${tmpdir}/source.txt"
destination="${tmpdir}/artifact.txt"
lock_file="${tmpdir}/downloads.json"
printf 'trusted artifact\n' >"${source_file}"
checksum="$(si_sha256 "${source_file}")"

printf '{"schema_version":1,"artifacts":{"fixture":{"url":"file://%s","sha256":"%s"}}}\n' \
  "${source_file}" "${checksum}" >"${lock_file}"
SI_DOWNLOAD_LOCK_FILE="${lock_file}"
si_download_locked fixture "${destination}"
cmp -s "${source_file}" "${destination}"

printf '{"schema_version":1,"artifacts":{"bad":{"url":"file://%s","sha256":"%064d"}}}\n' \
  "${source_file}" 0 >"${lock_file}"
assert_failure "mismatched checksum is rejected" si_download_locked bad "${destination}"
[[ ! -f "${destination}.part" ]]
assert_failure "missing lock entry is rejected" si_download_locked missing "${destination}"

printf 'Download tests: OK\n'
