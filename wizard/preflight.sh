#!/usr/bin/env bash
# Wizard preflight wrapper — uses lib/preflight.sh + metadata/modules/*.json.

wiz_preflight_check_one() {
  si_preflight_check "$1"
}

# Prints lines: id|VERDICT|reason
wiz_preflight_run() {
  local id line verdict reason
  for id in "${WIZ_MODULES[@]+"${WIZ_MODULES[@]}"}"; do
    line="$(wiz_preflight_check_one "${id}")"
    verdict="${line%%|*}"
    reason="${line#*|}"
    printf '%s|%s|%s\n' "${id}" "${verdict}" "${reason}"
  done
}
