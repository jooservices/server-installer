#!/usr/bin/env bash
# Interactive / unattended frontend for server-installer CLI.
set -euo pipefail

SI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${SI_ROOT}/lib/common.sh"
si_bootstrap
# shellcheck source=state.sh
source "${SI_ROOT}/wizard/state.sh"
# shellcheck source=ui.sh
source "${SI_ROOT}/wizard/ui.sh"
# shellcheck source=catalog.sh
source "${SI_ROOT}/wizard/catalog.sh"
# shellcheck source=mutex.sh
source "${SI_ROOT}/wizard/mutex.sh"
# shellcheck source=preflight.sh
source "${SI_ROOT}/wizard/preflight.sh"
# shellcheck source=credentials.sh
source "${SI_ROOT}/wizard/credentials.sh"
# shellcheck source=report.sh
source "${SI_ROOT}/wizard/report.sh"

SI_BIN="${SI_ROOT}/bin/server-installer"

wiz_usage() {
  cat <<EOF
Usage: server-installer-wizard [options]

Options:
  --express              Express mode (profile)
  --custom               Custom module picker
  --unattended           Non-interactive (requires --profile or --modules)
  --profile NAME         Profile id
  --modules CSV          Module list (comma-separated)
  --force                Continue past preflight BLOCK
  --resume               Resume from saved mid-run state
  --fresh                Ignore saved state; start clean
  --no-whiptail          Force plain text UI
  -h, --help             Show help

State file: \${SI_WIZARD_STATE:-/tmp/si-wizard-state.json}
EOF
}

wiz_parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --express) WIZ_MODE=express; shift ;;
      --custom) WIZ_MODE=custom; shift ;;
      --unattended) WIZ_MODE=unattended; shift ;;
      --profile) WIZ_PROFILE="${2:-}"; shift 2 ;;
      --modules) wiz_modules_set_csv "${2:-}"; shift 2 ;;
      --force) WIZ_FORCE_PREFLIGHT=true; shift ;;
      --resume) WIZ_RESUME=yes; shift ;;
      --fresh) WIZ_RESUME=no; wiz_state_clear; shift ;;
      --no-whiptail) export WIZ_NO_WHIPTAIL=true; shift ;;
      -h|--help) wiz_usage; exit 0 ;;
      *) log_error "Unknown argument: $1"; wiz_usage; exit 1 ;;
    esac
  done
}

wiz_maybe_resume() {
  if [[ "${WIZ_RESUME}" == "no" ]]; then
    return 0
  fi
  if ! wiz_state_exists; then
    if [[ "${WIZ_RESUME}" == "yes" ]]; then
      log_error "No wizard state at ${WIZ_STATE_FILE}"
      exit 1
    fi
    return 0
  fi

  local do_resume=false
  if [[ "${WIZ_RESUME}" == "yes" ]]; then
    do_resume=true
  elif [[ "${WIZ_MODE}" == "unattended" ]]; then
    # Unattended only resumes when --resume is set.
    return 0
  else
    if wiz_yesno "Resume" "Found saved wizard state (${WIZ_STATE_FILE}). Resume?" "yes"; then
      do_resume=true
    else
      wiz_state_clear
      return 0
    fi
  fi

  if [[ "${do_resume}" == "true" ]]; then
    wiz_state_load
    log_info "Resumed wizard at stage=${WIZ_STAGE} modules=$(wiz_modules_csv)"
  fi
}

wiz_step_mode() {
  if wiz_stage_done mode; then
    return 0
  fi
  if [[ -n "${WIZ_MODE}" ]]; then
    wiz_state_save mode
    return 0
  fi
  local choice
  choice="$(wiz_menu "Mode" \
    express "Express — profile based" \
    custom "Custom — pick modules" \
    quit "Quit")" || exit 1
  case "${choice}" in
    express|custom) WIZ_MODE="${choice}" ;;
    *) exit 0 ;;
  esac
  wiz_state_save mode
}

wiz_profile_apply_env() {
  local profile="$1"
  local line key val
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    # Prefer existing wizard/shell values.
    if [[ -n "${WIZ_ENV[$key]:-}" || -n "${!key:-}" ]]; then
      continue
    fi
    wiz_env_set "${key}" "${val}"
  done < <(si_profile_env_lines "${profile}")
}

wiz_step_express() {
  if wiz_stage_done select; then
    return 0
  fi
  if [[ -n "${WIZ_PROFILE}" ]]; then
    local mods
    mods="$(si_profile_modules "${WIZ_PROFILE}")"
    # shellcheck disable=SC2206
    WIZ_MODULES=(${mods})
    wiz_profile_apply_env "${WIZ_PROFILE}"
    wiz_state_save select
    return 0
  fi
  local -a args=()
  local p
  while IFS= read -r p; do
    [[ -z "${p}" ]] && continue
    args+=("${p}" "${p}")
  done < <(wiz_list_profiles)
  if [[ ${#args[@]} -eq 0 ]]; then
    log_error "No profiles in ${SI_PROFILES_DIR}"
    exit 1
  fi
  WIZ_PROFILE="$(wiz_menu "Profile" "${args[@]}")" || exit 1
  local mods
  mods="$(si_profile_modules "${WIZ_PROFILE}")"
  # shellcheck disable=SC2206
  WIZ_MODULES=(${mods})
  wiz_profile_apply_env "${WIZ_PROFILE}"
  wiz_state_save select
}

wiz_step_custom() {
  if wiz_stage_done select; then
    return 0
  fi
  if [[ ${#WIZ_MODULES[@]} -gt 0 ]]; then
    wiz_state_save select
    return 0
  fi

  wiz_catalog_load
  local area raw
  local -a check_args=()

  while IFS= read -r area; do
    [[ -z "${area}" ]] && continue
    check_args+=("${area}" "${area}" "on")
  done < <(wiz_catalog_areas)

  raw="$(wiz_checklist "Areas to configure" "${check_args[@]}")" || exit 1
  # shellcheck disable=SC2206
  local -a areas=(${raw//\"/})

  WIZ_MODULES=()
  for area in "${areas[@]+"${areas[@]}"}"; do
    check_args=()
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      local id="${line%%|*}"
      local title="${line#*|}"
      check_args+=("${id}" "${title}" "off")
    done < <(wiz_catalog_items "${area}")
    [[ ${#check_args[@]} -eq 0 ]] && continue
    raw="$(wiz_checklist "Modules: ${area}" "${check_args[@]}")" || continue
    # shellcheck disable=SC2206
    local -a picked=(${raw//\"/})
    wiz_modules_add "${picked[@]+"${picked[@]}"}"
  done

  if [[ ${#WIZ_MODULES[@]} -eq 0 ]]; then
    log_error "No modules selected"
    exit 1
  fi
  wiz_state_save select
}

wiz_step_mutex() {
  if wiz_stage_done mutex; then
    return 0
  fi
  local conflicts
  conflicts="$(wiz_mutex_conflicts || true)"
  if [[ -z "${conflicts}" ]]; then
    wiz_state_save mutex
    return 0
  fi
  if [[ "${WIZ_MODE}" == "unattended" ]]; then
    wiz_mutex_resolve_keep_first
    wiz_state_save mutex
    return 0
  fi
  local left right force choice
  while IFS='|' read -r left right force; do
    [[ -z "${left}" ]] && continue
    choice="$(wiz_menu "Mutex: ${left} vs ${right}" \
      keep_left "Keep ${left}" \
      keep_right "Keep ${right}" \
      drop_both "Drop both")" || choice=keep_left
    case "${choice}" in
      keep_left) wiz_modules_remove "${right}" ;;
      keep_right) wiz_modules_remove "${left}" ;;
      drop_both) wiz_modules_remove "${left}"; wiz_modules_remove "${right}" ;;
    esac
  done <<<"${conflicts}"
  wiz_state_save mutex
}

wiz_step_credentials() {
  if wiz_stage_done credentials; then
    wiz_env_export_all
    return 0
  fi
  wiz_credentials_collect
  wiz_state_save credentials
}

wiz_step_preflight() {
  if wiz_stage_done preflight; then
    return 0
  fi
  local body="" id verdict reason
  WIZ_PREFLIGHT_BLOCKS=0
  WIZ_PREFLIGHT_WARNS=0
  WIZ_PREFLIGHT_PASSES=0

  while IFS='|' read -r id verdict reason; do
    [[ -z "${id}" ]] && continue
    body+="$(printf '%-22s %-5s %s\n' "${id}" "${verdict}" "${reason}")"$'\n'
    case "${verdict}" in
      BLOCK) WIZ_PREFLIGHT_BLOCKS=$((WIZ_PREFLIGHT_BLOCKS + 1)) ;;
      WARN) WIZ_PREFLIGHT_WARNS=$((WIZ_PREFLIGHT_WARNS + 1)) ;;
      *) WIZ_PREFLIGHT_PASSES=$((WIZ_PREFLIGHT_PASSES + 1)) ;;
    esac
  done < <(wiz_preflight_run)

  body+=$'\n'"PASS=${WIZ_PREFLIGHT_PASSES} WARN=${WIZ_PREFLIGHT_WARNS} BLOCK=${WIZ_PREFLIGHT_BLOCKS}"

  if [[ "${WIZ_MODE}" != "unattended" ]]; then
    wiz_msg "Preflight" "${body}"
  else
    printf '%s\n' "${body}"
  fi

  if [[ "${WIZ_PREFLIGHT_BLOCKS}" -gt 0 && "${WIZ_FORCE_PREFLIGHT}" != "true" ]]; then
    if [[ "${WIZ_MODE}" == "unattended" ]]; then
      log_error "Preflight BLOCK — re-run with --force to continue"
      exit 2
    fi
    if wiz_yesno "Preflight" "There are BLOCK items. Force continue anyway?" "no"; then
      WIZ_FORCE_PREFLIGHT=true
    else
      log_error "Aborted due to preflight BLOCK"
      exit 2
    fi
  fi
  wiz_state_save preflight
}

wiz_step_review() {
  if wiz_stage_done review; then
    return 0
  fi
  local body
  body="$(printf 'Mode: %s\nProfile: %s\nModules: %s\n' \
    "${WIZ_MODE}" "${WIZ_PROFILE:-"(none)"}" "$(wiz_modules_csv)")"
  if [[ "${WIZ_MODE}" == "unattended" ]]; then
    printf '%s\n' "${body}"
    wiz_state_save review
    return 0
  fi
  if ! wiz_yesno "Review — Apply now?" "${body}" "yes"; then
    log_info "Cancelled at review (state kept for --resume)"
    exit 0
  fi
  wiz_state_save review
}

wiz_run_cli() {
  local phase="$1"
  local -a cmd=("${SI_BIN}" "${phase}")

  if [[ -n "${WIZ_PROFILE}" && ${#WIZ_MODULES[@]} -eq 0 ]]; then
    cmd+=(--profile "${WIZ_PROFILE}")
  else
    cmd+=(--modules "$(wiz_modules_csv)")
  fi

  wiz_env_export_all
  log_info "Running: ${cmd[*]}"
  "${cmd[@]}"
}

wiz_main() {
  wiz_state_reset
  wiz_parse_args "$@"
  wiz_maybe_resume

  if [[ "${WIZ_MODE}" != "unattended" && "${WIZ_STAGE}" == "init" ]]; then
    wiz_banner
    if ! wiz_yesno "Welcome" "Continue with server-installer wizard?" "yes"; then
      exit 0
    fi
  fi

  wiz_step_mode

  case "${WIZ_MODE}" in
    express)
      wiz_step_express
      ;;
    custom)
      wiz_step_custom
      ;;
    unattended)
      if ! wiz_stage_done select; then
        if [[ -n "${WIZ_PROFILE}" && ${#WIZ_MODULES[@]} -eq 0 ]]; then
          local mods
          mods="$(si_profile_modules "${WIZ_PROFILE}")"
          # shellcheck disable=SC2206
          WIZ_MODULES=(${mods})
          wiz_profile_apply_env "${WIZ_PROFILE}"
        fi
        if [[ ${#WIZ_MODULES[@]} -eq 0 ]]; then
          log_error "Unattended requires --profile or --modules"
          exit 1
        fi
        wiz_state_save select
      fi
      ;;
    *)
      log_error "No mode selected"
      exit 1
      ;;
  esac

  wiz_step_mutex
  wiz_step_credentials
  wiz_step_preflight
  wiz_step_review

  local rc=0
  set +e
  if ! wiz_stage_done apply; then
    wiz_run_cli apply
    rc=$?
    if [[ "${rc}" -eq 0 ]]; then
      wiz_state_save apply
    fi
  fi
  if [[ "${rc}" -eq 0 ]] && ! wiz_stage_done verify; then
    wiz_run_cli verify
    rc=$?
    if [[ "${rc}" -eq 0 ]]; then
      wiz_state_save verify
    fi
  fi
  set -e

  local status="ok"
  [[ "${rc}" -eq 0 ]] || status="failed(${rc})"
  local report
  report="$(wiz_report_write "${status}")"
  log_info "Report: ${report}"

  if [[ "${rc}" -eq 0 ]]; then
    wiz_state_save "done"
    wiz_state_clear
  else
    log_info "State kept at ${WIZ_STATE_FILE} — re-run with --resume"
  fi

  if [[ "${WIZ_MODE}" != "unattended" ]]; then
    wiz_msg "Done" "Status: ${status}"$'\n'"Report: ${report}"
  fi
  exit "${rc}"
}

wiz_main "$@"
