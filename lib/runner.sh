#!/usr/bin/env bash
# Module discovery, profile loading, plan/apply orchestration.

si_module_path() {
  local id="$1"
  local candidate

  while IFS= read -r -d '' candidate; do
    if grep -q "MODULE_ID=\"${id}\"" "${candidate}" 2>/dev/null \
      || grep -q "MODULE_ID='${id}'" "${candidate}" 2>/dev/null; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(find "${SI_MODULES_DIR}" -type f -name 'module.sh' -print0 2>/dev/null)

  return 1
}

si_load_module() {
  local id="$1"
  local path
  path="$(si_module_path "${id}")" || {
    log_error "Unknown module: ${id}"
    return 1
  }

  # shellcheck disable=SC1090
  source "${path}"
}

si_profile_path() {
  local profile="$1"
  printf '%s/%s.json' "${SI_PROFILES_DIR}" "${profile}"
}

si_profile_modules() {
  local profile="$1"
  local file
  file="$(si_profile_path "${profile}")"

  if [[ ! -f "${file}" ]]; then
    log_error "Profile not found: ${file}"
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["modules"]))' "${file}"
  elif command -v jq >/dev/null 2>&1; then
    jq -r '.modules | join(" ")' "${file}"
  else
    log_error "Need python3 or jq to parse profiles."
    return 1
  fi
}

# Print KEY=value lines from profile env (no export).
si_profile_env_lines() {
  local profile="$1"
  local file
  file="$(si_profile_path "${profile}")"

  if [[ ! -f "${file}" ]]; then
    log_error "Profile not found: ${file}"
    return 1
  fi

  python3 -c '
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
env = data.get("env") or {}
for k, v in env.items():
    if v is None:
        continue
    print(f"{k}={v}")
' "${file}"
}

# Apply profile env defaults. Does not override variables already set/non-empty.
si_profile_apply_env() {
  local profile="$1"
  local line key val
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    if [[ -n "${key}" && -z "${!key:-}" ]]; then
      export "${key}=${val}"
      log_info "profile env: ${key}=${val}"
    fi
  done < <(si_profile_env_lines "${profile}")
}

# Unset previous module function hooks before loading next module.
si_clear_module_hooks() {
  unset -f module_check module_plan module_apply module_verify 2>/dev/null || true
  unset MODULE_ID MODULE_TITLE 2>/dev/null || true
}

si_run_modules() {
  local mode="$1" # plan|apply|doctor|verify
  shift
  local modules=("$@")
  local id
  local failed=0
  local idx=0
  local total="${#modules[@]}"

  for id in "${modules[@]}"; do
    idx=$((idx + 1))
    si_clear_module_hooks
    if ! si_load_module "${id}"; then
      failed=1
      continue
    fi

    log_info "[${idx}/${total}] ${MODULE_TITLE:-${id}} (${mode})"

    case "${mode}" in
      doctor|plan)
        module_plan
        if module_check; then
          log_success "${id}: already satisfied"
        else
          log_plan "${id}: changes needed"
        fi
        ;;
      apply)
        if module_check; then
          log_skip "${id}: already satisfied"
        else
          if ! module_apply; then
            log_error "${id}: apply failed"
            failed=1
            continue
          fi
        fi
        if ! module_verify; then
          log_error "${id}: verify failed"
          failed=1
        else
          log_success "${id}: ok"
        fi
        ;;
      verify)
        if module_verify; then
          log_success "${id}: verify ok"
        else
          log_error "${id}: verify failed"
          failed=1
        fi
        ;;
      *)
        log_error "Unknown mode: ${mode}"
        return 1
        ;;
    esac
  done

  return "${failed}"
}
