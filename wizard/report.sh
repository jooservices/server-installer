#!/usr/bin/env bash
# Write a simple local run report (no secrets values).

wiz_report_write() {
  local status="$1"
  local dir="${SI_REPORT_DIR:-${HOME}/si-reports}"
  mkdir -p "${dir}"
  local stamp file
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  file="${dir}/run-${stamp}.md"

  {
    printf '# server-installer wizard report\n\n'
    printf -- '- UTC: %s\n' "${stamp}"
    printf -- '- Status: %s\n' "${status}"
    printf -- '- Mode: %s\n' "${WIZ_MODE}"
    printf -- '- Profile: %s\n' "${WIZ_PROFILE:-"(none)"}"
    printf -- '- Modules: %s\n' "$(wiz_modules_csv)"
    printf -- '- OS: %s %s arch=%s systemd=%s\n' \
      "${SI_OS_ID}" "${SI_OS_VERSION}" "${SI_CPU_ARCH}" "${SI_SYSTEMD_ACTIVE}"
    printf '\n## Env keys set\n\n'
    local k
    if [[ ${#WIZ_ENV[@]} -gt 0 ]]; then
      for k in "${!WIZ_ENV[@]}"; do
        printf -- '- %s=(redacted)\n' "${k}"
      done
    else
      printf -- '- (none via wizard)\n'
    fi
    printf '\n## Command\n\n```bash\n'
    if [[ -n "${WIZ_PROFILE}" && ${#WIZ_MODULES[@]} -eq 0 ]]; then
      printf '%s apply --profile %s\n' "${SI_ROOT}/bin/server-installer" "${WIZ_PROFILE}"
    else
      printf '%s apply --modules %s\n' "${SI_ROOT}/bin/server-installer" "$(wiz_modules_csv)"
    fi
    printf '```\n'
  } >"${file}"

  WIZ_REPORT_FILE="${file}"
  printf '%s\n' "${file}"
}
