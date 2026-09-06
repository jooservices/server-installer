# Testing

## Local

```bash
make lint                 # shellcheck
make metadata-test        # metadata coverage and schema
make preflight-test       # PASS/WARN/BLOCK behavior
make e2e-coverage         # every MODULE_ID referenced in E2E
make e2e-essentials
make e2e                  # full matrix (required before Done)
```

Suites: `bash ./tests/run_e2e.sh <name>` — see `tests/run_e2e.sh` usage.

Needs Docker on the host. Set `E2E_OS=ubuntu24|debian12|rocky9` to select the smoke image.

## CI

PR gate: validate → shellcheck → security → metadata/preflight tests → coverage map + essentials + wizard E2E → OS smoke matrix → **Coverage upload** aggregate.

Documented in [`../WORKFLOWS.md`](../WORKFLOWS.md).
