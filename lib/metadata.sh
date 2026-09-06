#!/usr/bin/env bash
# Validation for module preflight metadata.

si_metadata_validate_file() {
  local file="$1"

  if [[ ! -f "${file}" ]]; then
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    return 2
  fi

  SI_METADATA_FILE="${file}" python3 - <<'PY'
import json
import os
import sys

path = os.environ["SI_METADATA_FILE"]
required = {
    "requires_systemd",
    "os_family",
    "arch",
    "needs_lvm",
    "needs_docker",
    "note",
}
families = {"any", "debian", "redhat"}
architectures = {"any", "amd64", "arm64"}

try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except (OSError, json.JSONDecodeError):
    sys.exit(1)

if not isinstance(data, dict) or set(data) != required:
    sys.exit(1)

if not all(isinstance(data[field], bool) for field in ("requires_systemd", "needs_lvm", "needs_docker")):
    sys.exit(1)
if not isinstance(data["note"], str):
    sys.exit(1)

for field, allowed in (("os_family", families), ("arch", architectures)):
    values = data[field]
    if not isinstance(values, list) or not values or not all(isinstance(value, str) for value in values):
        sys.exit(1)
    if not set(values).issubset(allowed) or len(set(values)) != len(values):
        sys.exit(1)
    if "any" in values and values != ["any"]:
        sys.exit(1)

sys.exit(0)
PY
}
