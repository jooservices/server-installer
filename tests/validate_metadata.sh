#!/usr/bin/env bash
# Validate module coverage and the preflight metadata schema.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 is required for metadata validation\n' >&2
  exit 1
fi

module_ids="$({
  find "${ROOT}/modules" -type f -name module.sh -exec awk -F'"' '/^MODULE_ID="/ {print $2}' {} +
} | sort -u)"
metadata_ids="$(find "${ROOT}/metadata/modules" -type f -name '*.json' -exec basename {} .json \; | sort -u)"

if [[ "${module_ids}" != "${metadata_ids}" ]]; then
  printf '%s\n' "Module and metadata IDs differ" >&2
  printf '%s\n' "Modules:" "${module_ids}" "Metadata:" "${metadata_ids}" >&2
  exit 1
fi

while IFS= read -r id; do
  [[ -n "${id}" ]] || continue
  file="${ROOT}/metadata/modules/${id}.json"
  if si_metadata_validate_file "${file}"; then
    :
  else
    validation_status="$?"
    if [[ "${validation_status}" -eq 2 ]]; then
      printf 'python3 is required for metadata validation\n' >&2
    fi
    printf 'Invalid metadata: %s\n' "${file}" >&2
    exit 1
  fi
done <<<"${module_ids}"

printf 'Metadata validation: OK (%s modules)\n' "$(printf '%s\n' "${module_ids}" | awk 'NF {count++} END {print count + 0}')"
