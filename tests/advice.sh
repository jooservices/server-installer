#!/usr/bin/env bash
# Unit checks for read-only sizing advice.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

SI_ADVISE_MEMORY_MIB=2048
SI_ADVISE_CPU_CORES=4
SI_PHP_VERSION=8.5
output="$(si_advice_run php mariadb)"

if [[ "${output}" != *"Read-only capacity advice"* || "${output}" != *"pm.max_children: <unset> -> 8"* ]]; then
  printf 'PHP advice is incomplete:\n%s\n' "${output}" >&2
  exit 1
fi
if [[ "${output}" != *"innodb_buffer_pool_size: <unset> -> 512M"* || "${output}" != *"max_connections: <unset> -> 100"* ]]; then
  printf 'Database advice is incomplete:\n%s\n' "${output}" >&2
  exit 1
fi

output="$(si_advice_run nginx)"
if [[ "${output}" != *"No capacity advisor is available"* ]]; then
  printf 'Unexpected unsupported-module advice:\n%s\n' "${output}" >&2
  exit 1
fi

printf 'Advice tests: OK\n'
