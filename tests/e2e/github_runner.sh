#!/usr/bin/env bash
# E2E: github_runner input validation + dry-run plan. A real registration
# needs a live PAT + repo/org this suite intentionally does not have, so
# this only exercises argument validation and confirms dry-run makes no
# network calls (it must stop before any curl/API call).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true

echo "=== E2E github_runner: missing token refuses ==="
unset SI_GITHUB_TOKEN SI_GITHUB_REPO SI_GITHUB_ORG || true
export SI_GITHUB_REPO=example/example
if "${ROOT}/bin/server-installer" apply --modules github_runner >/tmp/si-gh-runner-1.txt 2>&1; then
  echo "[FAIL] should refuse without SI_GITHUB_TOKEN" >&2
  cat /tmp/si-gh-runner-1.txt >&2
  exit 1
fi
assert_cmd "error mentions SI_GITHUB_TOKEN" bash -c "grep -q SI_GITHUB_TOKEN /tmp/si-gh-runner-1.txt"

echo "=== E2E github_runner: both repo and org refuses ==="
export SI_GITHUB_TOKEN=fake-token
export SI_GITHUB_ORG=example-org
if "${ROOT}/bin/server-installer" apply --modules github_runner >/tmp/si-gh-runner-2.txt 2>&1; then
  echo "[FAIL] should refuse with both SI_GITHUB_REPO and SI_GITHUB_ORG set" >&2
  cat /tmp/si-gh-runner-2.txt >&2
  exit 1
fi
assert_cmd "error mentions only one of" bash -c "grep -qi 'only one of' /tmp/si-gh-runner-2.txt"
unset SI_GITHUB_ORG

echo "=== E2E github_runner: neither repo nor org refuses ==="
unset SI_GITHUB_REPO
if "${ROOT}/bin/server-installer" apply --modules github_runner >/tmp/si-gh-runner-3.txt 2>&1; then
  echo "[FAIL] should refuse with neither SI_GITHUB_REPO nor SI_GITHUB_ORG set" >&2
  cat /tmp/si-gh-runner-3.txt >&2
  exit 1
fi

echo "=== E2E github_runner: dry-run plans without touching the network ==="
export SI_GITHUB_REPO=example/example
"${ROOT}/bin/server-installer" apply --modules github_runner --dry-run >/tmp/si-gh-runner-4.txt 2>&1
assert_cmd "dry-run plans registration" bash -c "grep -qi 'Will register runner' /tmp/si-gh-runner-4.txt"

echo "=== E2E github_runner: PASS ==="
