# Testing

## Local

```bash
make lint                 # shellcheck
make metadata-test        # metadata coverage and schema
make preflight-test       # PASS/WARN/BLOCK behavior
make macos-test           # macOS branches, mocked — no Darwin/brew needed
make e2e-coverage         # every MODULE_ID referenced in E2E
make e2e-essentials
make e2e                  # full matrix (required before Done)
```

Suites: `bash ./tests/run_e2e.sh <name>` — see `tests/run_e2e.sh` usage.

Needs Docker on the host. Set `E2E_OS=ubuntu24|debian12|rocky9` to select the smoke image. `tests/e2e/macos.sh` is the exception: it does real installs and must run on an actual Mac (Docker cannot run macOS containers) — it self-skips when not on Darwin, and never under root.

## CI

PR gate: validate → shellcheck → security → metadata/preflight tests → coverage map + essentials + wizard E2E → OS smoke matrix → **Coverage upload** aggregate.

macOS is a separate, non-required workflow (`macos-smoke.yml`, `macos-latest` runner) — path-filtered to macOS-relevant files plus manual dispatch, kept out of the required gate since hosted macOS runners are slower/costlier than Linux.

Documented in [`../WORKFLOWS.md`](../WORKFLOWS.md).
