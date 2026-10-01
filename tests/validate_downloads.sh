#!/usr/bin/env bash
# Validate the immutable download lockfile schema.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lock_file="${ROOT}/metadata/downloads.json"

python3 -c '
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if data.get("schema_version") != 1 or not isinstance(data.get("artifacts"), dict):
    raise SystemExit("downloads.json must contain schema_version 1 and artifacts")

for name, artifact in data["artifacts"].items():
    if not isinstance(name, str) or not name:
        raise SystemExit("artifact name must be non-empty")
    if set(artifact) != {"url", "sha256"}:
        raise SystemExit(f"{name}: expected only url and sha256")
    if not artifact["url"].startswith("https://"):
        raise SystemExit(f"{name}: URL must use HTTPS")
    if not re.fullmatch(r"[0-9a-f]{64}", artifact["sha256"]):
        raise SystemExit(f"{name}: SHA-256 must be lower-case hexadecimal")
' "${lock_file}"

printf 'Download lock validation: OK\n'
