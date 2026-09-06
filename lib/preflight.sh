#!/usr/bin/env bash
# Preflight: compare host facts to metadata/modules/<id>.json.
# Verdicts: PASS | WARN | BLOCK
# Missing or invalid metadata → BLOCK. Metadata is part of the safety gate.

si_preflight_meta_path() {
  printf '%s/%s.json' "${SI_METADATA_DIR}" "$1"
}

# Prints space-separated list or scalar string; empty → use default.
si_preflight_field() {
  local file="$1" field="$2" default="${3:-}"
  if [[ ! -f "${file}" ]]; then
    printf '%s' "${default}"
    return 0
  fi
  SI_PF_FILE="${file}" SI_PF_FIELD="${field}" SI_PF_DEFAULT="${default}" python3 -c '
import json, os
path = os.environ["SI_PF_FILE"]
field = os.environ["SI_PF_FIELD"]
default = os.environ["SI_PF_DEFAULT"]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    print(default)
    raise SystemExit
val = data.get(field)
if val is None:
    print(default)
elif isinstance(val, list):
    print(" ".join(str(x) for x in val))
elif isinstance(val, bool):
    print("true" if val else "false")
else:
    print(str(val))
'
}

# Usage: si_preflight_check <module_id>
# Prints: VERDICT|reason
si_preflight_check() {
  local id="$1"
  local file families archs note
  file="$(si_preflight_meta_path "${id}")"

  if ! si_metadata_validate_file "${file}"; then
    printf 'BLOCK|Missing or invalid preflight metadata for module %s\n' "${id}"
    return 0
  fi

  families="$(si_preflight_field "${file}" "os_family" "any")"
  if [[ "${families}" != "any" && -n "${families}" ]]; then
    if [[ " ${families} " != *" ${SI_OS_FAMILY} "* ]]; then
      printf 'BLOCK|Unsupported OS family %s (requires: %s)\n' "${SI_OS_FAMILY}" "${families}"
      return 0
    fi
  fi

  archs="$(si_preflight_field "${file}" "arch" "any")"
  if [[ "${archs}" != "any" && -n "${archs}" ]]; then
    if [[ " ${archs} " != *" ${SI_CPU_ARCH} "* ]]; then
      if [[ " ${archs} " == *" amd64 "* ]]; then
        printf 'WARN|No native %s build — may need amd64 emulation\n' "${SI_CPU_ARCH}"
        return 0
      fi
      printf 'BLOCK|Unsupported architecture %s (requires: %s)\n' "${SI_CPU_ARCH}" "${archs}"
      return 0
    fi
  fi

  if [[ "$(si_preflight_field "${file}" "needs_lvm" "false")" == "true" && "${SI_LVM_AVAILABLE}" != "true" ]]; then
    printf 'BLOCK|LVM required but not available on this host\n'
    return 0
  fi

  if [[ "$(si_preflight_field "${file}" "requires_systemd" "false")" == "true" && "${SI_SYSTEMD_ACTIVE}" != "true" ]]; then
    printf 'BLOCK|Requires systemd (not active in this environment)\n'
    return 0
  fi

  if [[ "$(si_preflight_field "${file}" "needs_docker" "false")" == "true" ]]; then
    if [[ "${SI_SYSTEMD_ACTIVE}" != "true" ]]; then
      printf 'WARN|Container/host without systemd — DinD or manual dockerd may be required\n'
      return 0
    fi
    if ! command -v docker >/dev/null 2>&1; then
      printf 'WARN|Docker required — install docker module first or ensure dockerd\n'
      return 0
    fi
  fi

  note="$(si_preflight_field "${file}" "note" "")"
  printf 'PASS|%s\n' "${note}"
}
