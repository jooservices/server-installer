#!/usr/bin/env bash
# Wizard state (selected profile/modules/env) + mid-run resume.

WIZ_MODE="${WIZ_MODE:-}"
WIZ_PROFILE="${WIZ_PROFILE:-}"
WIZ_MODULES=()
WIZ_FORCE_PREFLIGHT="${WIZ_FORCE_PREFLIGHT:-false}"
WIZ_STAGE="${WIZ_STAGE:-init}"
WIZ_RESUME="${WIZ_RESUME:-ask}"   # ask|yes|no
WIZ_STATE_FILE="${SI_WIZARD_STATE:-/tmp/si-wizard-state.json}"
declare -A WIZ_ENV=()

wiz_state_reset() {
  WIZ_MODE=""
  WIZ_PROFILE=""
  WIZ_MODULES=()
  WIZ_FORCE_PREFLIGHT=false
  WIZ_STAGE="init"
  WIZ_ENV=()
}

wiz_modules_csv() {
  local IFS=,
  printf '%s' "${WIZ_MODULES[*]}"
}

wiz_modules_add() {
  local id
  for id in "$@"; do
    [[ -z "${id}" ]] && continue
    local m
    for m in "${WIZ_MODULES[@]+"${WIZ_MODULES[@]}"}"; do
      [[ "${m}" == "${id}" ]] && continue 2
    done
    WIZ_MODULES+=("${id}")
  done
}

wiz_modules_remove() {
  local drop="$1"
  local keep=()
  local m
  for m in "${WIZ_MODULES[@]+"${WIZ_MODULES[@]}"}"; do
    [[ "${m}" == "${drop}" ]] && continue
    keep+=("${m}")
  done
  WIZ_MODULES=("${keep[@]+"${keep[@]}"}")
}

wiz_modules_set_csv() {
  WIZ_MODULES=()
  local raw="$1" part
  local -a parts=()
  IFS=',' read -r -a parts <<<"${raw}"
  for part in "${parts[@]+"${parts[@]}"}"; do
    part="$(echo "${part}" | tr -d '[:space:]')"
    [[ -n "${part}" ]] && WIZ_MODULES+=("${part}")
  done
}

wiz_env_set() {
  local key="$1" val="$2"
  WIZ_ENV["${key}"]="${val}"
  export "${key}=${val}"
}

wiz_env_export_all() {
  local k
  for k in "${!WIZ_ENV[@]}"; do
    export "${k}=${WIZ_ENV[$k]}"
  done
}

wiz_state_clear() {
  rm -f "${WIZ_STATE_FILE}"
}

wiz_state_exists() {
  [[ -f "${WIZ_STATE_FILE}" ]]
}

wiz_state_save() {
  WIZ_STAGE="${1:-${WIZ_STAGE}}"
  local env_json
  env_json="$(
    {
      local k
      for k in "${!WIZ_ENV[@]}"; do
        printf '%s\t%s\n' "${k}" "${WIZ_ENV[$k]}"
      done
    } | python3 -c '
import json, sys
env = {}
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line or "\t" not in line:
        continue
    k, v = line.split("\t", 1)
    env[k] = v
print(json.dumps(env))
'
  )"
  WIZ_STAGE="${WIZ_STAGE}" WIZ_MODE="${WIZ_MODE}" WIZ_PROFILE="${WIZ_PROFILE}" \
  WIZ_FORCE_PREFLIGHT="${WIZ_FORCE_PREFLIGHT}" WIZ_MODULES_CSV="$(wiz_modules_csv)" \
  WIZ_STATE_FILE="${WIZ_STATE_FILE}" WIZ_ENV_JSON="${env_json}" \
  python3 <<'PY'
import json, os
mods = [m for m in os.environ.get("WIZ_MODULES_CSV", "").split(",") if m]
state = {
    "stage": os.environ.get("WIZ_STAGE", "init"),
    "mode": os.environ.get("WIZ_MODE", ""),
    "profile": os.environ.get("WIZ_PROFILE", ""),
    "modules": mods,
    "force_preflight": os.environ.get("WIZ_FORCE_PREFLIGHT", "false") == "true",
    "env": json.loads(os.environ.get("WIZ_ENV_JSON") or "{}"),
}
with open(os.environ["WIZ_STATE_FILE"], "w", encoding="utf-8") as f:
    json.dump(state, f, indent=2)
    f.write("\n")
PY
}

wiz_state_load() {
  [[ -f "${WIZ_STATE_FILE}" ]] || return 1
  local loaded
  loaded="$(python3 <<PY
import json
with open(r"""${WIZ_STATE_FILE}""", encoding="utf-8") as f:
    s = json.load(f)
print(json.dumps({
    "stage": s.get("stage", "init"),
    "mode": s.get("mode", ""),
    "profile": s.get("profile", ""),
    "modules": ",".join(s.get("modules") or []),
    "force_preflight": "true" if s.get("force_preflight") else "false",
    "env": s.get("env") or {},
}))
PY
)"
  WIZ_STAGE="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["stage"])' <<<"${loaded}")"
  WIZ_MODE="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["mode"])' <<<"${loaded}")"
  WIZ_PROFILE="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["profile"])' <<<"${loaded}")"
  WIZ_FORCE_PREFLIGHT="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["force_preflight"])' <<<"${loaded}")"
  wiz_modules_set_csv "$(python3 -c 'import json,sys; print(json.load(sys.stdin)["modules"])' <<<"${loaded}")"
  local pair
  while IFS= read -r pair; do
    [[ -z "${pair}" ]] && continue
    wiz_env_set "${pair%%=*}" "${pair#*=}"
  done < <(python3 -c 'import json,sys
d=json.load(sys.stdin)["env"]
for k,v in d.items():
    print(f"{k}={v}")
' <<<"${loaded}")
  return 0
}

wiz_stage_rank() {
  case "$1" in
    init) echo 0 ;;
    mode) echo 1 ;;
    select) echo 2 ;;
    mutex) echo 3 ;;
    credentials) echo 4 ;;
    preflight) echo 5 ;;
    review) echo 6 ;;
    apply) echo 7 ;;
    verify) echo 8 ;;
    done) echo 9 ;;
    *) echo 0 ;;
  esac
}

# True if we already completed the named stage (resume past it).
# WIZ_STAGE is the last completed stage.
wiz_stage_done() {
  local target="$1"
  local cur_n target_n
  cur_n="$(wiz_stage_rank "${WIZ_STAGE}")"
  target_n="$(wiz_stage_rank "${target}")"
  [[ "${cur_n}" -ge "${target_n}" ]]
}
